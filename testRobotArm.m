%% 0. Python & SDK 準備  (clear classes は pyenv の前)
pe = pyenv("Version", fullfile(getenv("HOME"), "venv/xarm/bin/python3.10"), "ExecutionMode","InProcess");

% 1) wrapper モジュールを import
xarm = py.importlib.import_module("xarm.wrapper");

% 2) クラス XArmAPI を取り出す
XArmAPI = xarm.XArmAPI;
ROBOT_IP = "192.168.1.156";

%% 1. 接続 ＆ READY
arm = xarm.XArmAPI(ROBOT_IP, prot_flag=int32(1));  % V1 強制
pause(0.5);

arm.motion_enable(pyargs('enable',true));
arm.set_mode(int32(0));     % Position
arm.set_state(int32(0));    % Ready

mod = py.importlib.import_module("xarm");

%% 2. 現在 TCP 姿勢を取得
tmp  = arm.get_position();      % (code, [x y z r p y])
code = int32(tmp{1});

res = arm.set_servo_angle(pyargs( ...
    'servo_id', int32(6), ...
    'angle', -45, ...
    'is_radian', false, ...
    'wait', true, ...
    'relative', true, ...
    'timeout', 5 ...    % 最大 5 秒待機
    )) ;

if code == 0 % no error
    curr = cellfun(@double, cell(tmp{2}));
    xyz  = curr(1:3);
    fprintf("Current TCP XYZ = %s\n", mat2str(xyz,3));
else
    error("get_position failed, code=%d", code);
end
% 先端姿勢を [300, 0, 150, 180, 0, 0]° に動かす
res = arm.set_position(pyargs( ...
    'x', int32(xyz(1)), ...
    'y', int32(xyz(2)), ...
    'z', int32(xyz(3)), ...
    'roll', int32(180), ...
    'pitch', int32(0), ...
    'yaw', int32(30), ...
    'speed', int32(10), ...
    'is_radian', false, ...
    'wait', true, ...
    'timeout', int32(5) ...
    ));
disp(res)  % 0 以上なら成功


% 
% %% 3. 姿勢バリエーション
% % [roll, pitch, yaw] の配列
% poses = [
%     [0, 0, 0];         % 初期姿勢
%     [45, 0, 0];        % ロールを45度
%     [45, 30, 0];       % ピッチを30度
%     [45, 30, 45];      % ヨーを45度
%     [0, 30, 45];       % ロールを0度に戻す
%     [0, 0, 45];        % ピッチを0度に戻す
%     [0, 0, 0]          % 元の姿勢に戻す
%     ];
% 
% % ① 現在ジョイント角を取得
% curr  = arm.get_servo_angle   % 1×6 ベクトル (deg)
% 
% % 各姿勢に順次移動
% for i = 1:size(poses, 1)
%     roll = poses(i, 1);
%     pitch = poses(i, 2);
%     yaw = poses(i, 3);
% 
%     % arm.set_position(xyz(1), xyz(2), xyz(3), roll, pitch, yaw, wait=true);
%     %% 6 軸ジョイント角を決める  (deg)
%     angles = py.list([  273, -12,  294, ...
%         180,        -15,     -129 ]);    % 1×6 double
% 
%     %% Python で要求される型に変換
%     speed  = int32(30);            % int           ← 最大速度 (deg/s)
%     mvtime = int32(0);             % int           ← 0 なら自動軌道時間
% 
%     %% wait=true を付けてブロッキング実行
%     ret = arm.set_servo_angle(angles, speed, mvtime, ...
%         pyargs('wait', true));
% 
%     fprintf("API return = %d (0 = OK)\n", int32(ret));
% 
%     disp(['姿勢を変更: Roll=', num2str(roll), ' Pitch=', num2str(pitch), ' Yaw=', num2str(yaw)]);
%     pause(3);  % 各姿勢で1秒停止
% end

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