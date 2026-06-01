function matrix = imgaussian(image)
%IMGAUSSIAN この関数の概要をここに記述
%   詳細説明をここに記述
    image = double(image);
    image = image / 255;
    % ガウスノイズを作成（平均0, 分散0.01）
    noise = 0.1 * randn(size(image));
    
    % ノイズを加算
    noisy_img = double(image) + noise;
    
    % 範囲を[0,1]にクリップ
    noisy_img = min(max(noisy_img, 0), 1);

    matrix = uint8(noisy_img * 255);
end

