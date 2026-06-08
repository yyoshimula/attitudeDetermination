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
%[text] ## initializing 6th servo angle
res = arm.set_servo_angle(pyargs( ...
    'servo_id', int32(6), ...
    'angle', -360, ...
    'is_radian', false, ...
    'wait', true, ...
    'relative', false, ...
    'speed', 60, ...
    'timeout', 5));    % 最大 5 秒待機

pause(10);
%%
%[text] ## attitude
trainAtti = -360:20:0; % ここを書き換える
nAtti = length(trainAtti);

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
        'timeout', 5));    % 最大 5 秒待機

    pause(3)

    img = snapshot(cam);            % フレーム取得

    timeStamp = datetime('now', 'Format', 'yyyyMMdd-HHmmss');
    fName = strcat(string(timeStamp), '.jpeg');
    fPath = fullfile(saveDir, fName);
    imwrite(img, fPath);              % ファイル保存
    fprintf('Saved %s \n', fPath );

end
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

%[appendix]{"version":"1.0"}
%---
