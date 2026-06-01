cam = webcam("HDMI USB Camera");            % 必要なら名前で指定

%-- プレビューフィギュア --------------------------------------
app.UIAxes = figure;

% preview 先となる image オブジェクト
hIm = image(zeros(1080,1920,3,'uint8'));
% preview(cam,hIm);                                         % ← ライブ映像
