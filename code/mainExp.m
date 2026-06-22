%[text] # script for single spin experiment
function mainExp(cam, imageHandle)
%[text] ## initialization
% initialize robot arm — arm ハンドルは base から global 経由で共有する
% （start を押す前に、コマンドウィンドウで setRA を一度実行しておくこと）
global arm
if isempty(arm)
    % まだ接続していなければ自動で setRA を実行（pyenv→接続→READY、arm を global にセット）
    setRA;
end
if isempty(arm)
    error("mainExp:noArm", ...
        "setRA を実行しても arm を初期化できませんでした。アームの電源・ネットワーク(192.168.2.156)を確認してください。");
end

% initializing camera
% cam = liveSnap
% cam = webcam("HDMI USB Camera");            % 必要なら名前で指定
preview(cam, imageHandle);

%[text] ## 現在 TCP 姿勢を取得
% tmp  = arm.get_position();      % (code, [x y z r p y])
% code = int32(tmp{1});
% 
% if code == 0 % no error
%     curr = cellfun(@double, cell(tmp{2}));
%     xyz  = curr(1:3);
%     fprintf("Current TCP XYZ = %s\n", mat2str(xyz,3));
% else
%     error("get_position failed, code=%d", code);
% end
%%
%[text] ## 現在の J6 角度を取得して、そこから 360° を一定刻みで回転
ensureReady(arm);          % エラー/警告をクリアして READY(state=0) に入れ直す

step = 10;                 % 刻み [deg]（ここを書き換える）

% --- 現在の J6 角度を取得 ---
tmp  = arm.get_servo_angle(pyargs('servo_id', int32(6), 'is_radian', false));
code = double(tmp{1});
if code ~= 0
    error("mainExp:getAngle", "get_servo_angle 失敗 code=%d", code);
end
j6_0 = double(tmp{2});     % 現在の J6 角度 [deg]
fprintf("Current J6 = %.2f deg\n", j6_0);

% --- 余裕のある方向に 360° 回す（±360° の可動域を超えないように）---
dir = -sign(j6_0);         % 0以上 → 負方向、0未満 → 正方向
if dir == 0, dir = -1; end % j6_0 = 0 のときは負方向に回す
total = dir * 360;         % 総回転量 [deg]

%%
%[text] ## attitude
% 現在値 → 現在値+total を step 刻みで掃く絶対角の列
trainAtti = j6_0 : dir*abs(step) : j6_0 + total;
nAtti = numel(trainAtti);
fprintf("Sweep J6: %.1f -> %.1f deg, %d points\n", trainAtti(1), trainAtti(end), nAtti);

% 画像の保存先（無ければ作成）
saveDir = "/Users/ssdl/Documents/MATLAB/attitudeDetermination/data";
if ~isfolder(saveDir)
    mkdir(saveDir);
end

for i = 1:nAtti

    res = arm.set_servo_angle(pyargs( ...
        'servo_id', int32(6), ...
        'angle', trainAtti(i), ...
        'is_radian', false, ...
        'wait', true, ...
        'relative', false, ...
        'speed', 30, ...
        'timeout', 8));    % 最大 8 秒待機

    if double(res) ~= 0   % 0 以外は失敗 → 復旧して 1回だけ再試行
        warning("mainExp:moveRetry", ...
            "set_servo_angle 失敗 code=%d (i=%d, angle=%g)。状態を復旧して再試行。", ...
            int32(res), i, trainAtti(i));
        ensureReady(arm);
        res = arm.set_servo_angle(pyargs( ...
            'servo_id', int32(6), 'angle', trainAtti(i), 'is_radian', false, ...
            'wait', true, 'relative', false, 'speed', 30, 'timeout', 8));
        if double(res) ~= 0
            error("mainExp:moveFailed", ...
                "復旧後も移動に失敗 (code=%d, i=%d)。撮影を中断します。", int32(res), i);
        end
    end

    pause(3)

    img = safeSnapshot(cam, imageHandle);   % 移動成功を確認してからフレーム取得（タイムアウト耐性つき）

    timeStamp = datetime('now', 'Format', 'yyyyMMdd-HHmmss');
    fName = strcat(string(timeStamp), '.jpeg');
    fPath = fullfile(saveDir, fName);
    imwrite(img, fPath);              % ファイル保存
    fprintf('Saved %s \n', fPath );

end

disp('Finished')
%%
%[text] ## appendix
% 先端姿勢を [x, y, z, 0, 30, 0]° に動かす
% res = arm.set_position(pyargs( ...
%     'x', int32(xyz(1)), ...
%     'y', int32(xyz(2)), ...
%     'z', int32(xyz(3)), ...
%     'roll', int32(180), ...
%     'pitch', int32(0), ...
%     'yaw', int32(30), ...
%     'speed', int32(10), ...
%     'is_radian', false, ...
%     'wait', true, ...
%     'timeout', int32(5) ...
%     ));
% disp(res)  % 0 以上なら成功


% arm.disconnect();
% 4. 再接続（タイムアウトだけ指定する例）
% res_conn = arm.connect(pyargs( ...
%     'timeout', int32(5)   ...  % 待機タイムアウト（秒）
%     ));
% if res_conn < 0
%     error('再接続に失敗しました: %d', res_conn);
% else
%     disp('再接続に成功しました');
% end

end

%[text] ## helper: アームを READY(state=0) に入れ直す
function ensureReady(arm)
% エラー/警告をクリアして、motion_enable → Position モード → READY に戻す。
% code=9 (state is not ready to move) はこれで解消できることが多い。
arm.clean_warn();
arm.clean_error();
arm.motion_enable(pyargs('enable', true));
arm.set_mode(int32(0));     % Position
arm.set_state(int32(0));    % Ready
pause(0.5);
end

%[text] ## helper: snapshot をタイムアウトに強くする
function img = safeSnapshot(cam, imageHandle)
% HDMI/USB キャプチャ系カメラは「フレーム取得タイムアウト」をまれに出すので、
% 1回失敗しただけで実験を止めず、短い待機を挟んで再試行する。
% それでもダメな場合はプレビューを入れ直してストリームを起こしてから再度試す。
maxTry = 5;
for k = 1:maxTry
    try
        img = snapshot(cam);
        return;                       % 成功したら抜ける
    catch ME
        if k == maxTry
            rethrow(ME);              % 最後まで失敗したら本来のエラーを投げる
        end
        warning("mainExp:snapTimeout", ...
            "snapshot 失敗 (%d/%d): %s。再試行します。", k, maxTry, ME.message);
        pause(0.5);
        if k >= 2
            % 2回目以降の失敗ではプレビューを入れ直してストリームを起こす
            try, closePreview(cam); catch, end %#ok<CTCH>
            pause(0.3);
            try, preview(cam, imageHandle); catch, end %#ok<CTCH>
            pause(0.5);
        end
    end
end
end

%[appendix]{"version":"1.0"}
%---
