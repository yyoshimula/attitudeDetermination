%%  check roboto arm API


%% 0. Python と SDK をロード
pyenv("Version", fullfile(getenv("HOME"),"venv/xarm/bin/python3.10"), ...
    "ExecutionMode","InProcess");

%% 1. モジュール & クラスを取得  -------------【チェック①】
xw       = py.importlib.import_module("xarm.wrapper");
XArmAPI  = xw.xarm_api.XArmAPI;     % → ここでエラーなら SDK が壊れている

%% 2. インスタンス化して move_line の有無を判定  -------------【チェック②】
arm = XArmAPI("192.168.1.156", prot_flag=int32(1));   % IP を自分のに変更
hasML = py.hasattr(arm, "set_position")
fprintf("set_position available? %s\n", string(hasML));  % ← 必ず true になる


% 連続的な姿勢変更のための角度リスト
% [roll, pitch, yaw] の配列
poses = [
    [0, 0, 0];         % 初期姿勢
    [45, 0, 0];        % ロールを45度
    [45, 30, 0];       % ピッチを30度
    [45, 30, 45];      % ヨーを45度
    [0, 30, 45];       % ロールを0度に戻す
    [0, 0, 45];        % ピッチを0度に戻す
    [0, 0, 0]          % 元の姿勢に戻す
    ];

% 現在の位置と姿勢を取得
[ret, currentPose] = arm.get_position();
arm.set_position(current_x, current_y, current_z, roll, pitch, yaw, wait=true);
% 各姿勢に順次移動
for i = 1:size(poses, 1)
    roll = poses(i, 1);
    pitch = poses(i, 2);
    yaw = poses(i, 3);

    arm.set_position(current_x, current_y, current_z, roll, pitch, yaw, wait=true);
    disp(['姿勢を変更: Roll=', num2str(roll), ' Pitch=', num2str(pitch), ' Yaw=', num2str(yaw)]);
    pause(1);  % 各姿勢で1秒停止
end

arm.disconnect();