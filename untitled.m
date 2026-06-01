% =========================================================
%  RENK FİLTRELEME VE NESNE ALGILAMA
%  Kullanım: renk_filtresi.m dosyasını MATLAB'da çalıştırın
%  Test görseli: peppers.png (MATLAB'ın yerleşik görseli)
% =========================================================

clc; clear; close all;

% ---------------------------------------------------------
% 1. BÖLÜM: Görseli Yükleme ve Ön İzleme
% ---------------------------------------------------------
img = imread('yesilbiber.jpg');   % MATLAB yerleşik test görseli

figure('Name', 'Renk Filtreleme ve Nesne Algılama', ...
       'NumberTitle', 'off', ...
       'Position', [100 100 1200 600]);

subplot(2, 3, 1);
imshow(img);
title('1) Orijinal Görsel', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 2. BÖLÜM: RGB → HSV Dönüşümü
%    Neden HSV? Renk ayrımı RGB'ye göre çok daha sağlıklıdır.
%    H = Ton (renk açısı 0-1), S = Doygunluk, V = Parlaklık
% ---------------------------------------------------------
imgHSV = rgb2hsv(img);

H = imgHSV(:,:,1);   % Ton kanalı
S = imgHSV(:,:,2);   % Doygunluk kanalı
V = imgHSV(:,:,3);   % Parlaklık kanalı

subplot(2, 3, 2);
imshow(H);
title('2) HSV - Ton (H) Kanalı', 'FontWeight', 'bold', 'FontSize', 12);
colorbar;

% ---------------------------------------------------------
% 3. BÖLÜM: Kırmızı Renk Maskesi Oluşturma
%
%  Kırmızı rengin HSV'deki yeri:
%    - 0.00 < H < 0.08  (spektrumun başı)
%    - 0.85 < H < 1.00  (spektrumun sonu, yine kırmızı)
%  Bu yüzden iki aralığı birleştiriyoruz (OR işlemi).
%  Ayrıca düşük doygunluklu (soluk) pikselleri eliyoruz.
% ---------------------------------------------------------
maskKirmizi1 = (H >= 0.00 & H <= 0.08);   % kırmızı - alt aralık
maskKirmizi2 = (H >= 0.85 & H <= 1.00);   % kırmızı - üst aralık
maskDoygunluk = (S >= 0.35);               % soluk pikselleri ele

maskKirmizi = (maskKirmizi1 | maskKirmizi2) & maskDoygunluk;

% Morfolojik temizleme (Toolbox gerektirmez)
% Disk şeklinde yapısal eleman manuel oluştur (yarıçap=5)
r = 5;
[gx, gy] = meshgrid(-r:r, -r:r);
se = double((gx.^2 + gy.^2) <= r^2);

% Dilatasyon (conv2 ile): beyaz alanları genişlet
maskKirmizi = conv2(double(maskKirmizi), se, 'same') > 0;
% Erozyon (conv2 ile): gürültüyü sil
eleman = sum(se(:));
maskKirmizi = conv2(double(maskKirmizi), se, 'same') >= eleman;

subplot(2, 3, 3);
imshow(maskKirmizi);
title('3) İkili Maske (Kırmızı Alanlar)', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 4. BÖLÜM: Seçici Renklendirme
%    Kırmızı bölgeler renkli, diğerleri gri tonlamalı
% ---------------------------------------------------------
imgGri = repmat(rgb2gray(img), [1 1 3]);   % 3 kanallı gri görsel
imgFiltrelenmis = imgGri;                  % başlangıçta tamamen gri

mask3D = repmat(maskKirmizi, [1 1 3]);     % maskeyi 3 kanala genişlet
imgFiltrelenmis(mask3D) = img(mask3D);     % sadece kırmızı alanları renkli yap

subplot(2, 3, 4);
imshow(imgFiltrelenmis);
title('4) Seçici Renklendirme', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 5. BÖLÜM: Nesne Algılama ve Sınırlayıcı Kutu Çizimi
%    Toolbox gerektirmeyen bağlantılı bileşen analizi
% ---------------------------------------------------------
[satirSay, sutunSay] = size(maskKirmizi);
etiketler = zeros(satirSay, sutunSay);
nesneAdedi = 0;
for i = 1:satirSay
    for j = 1:sutunSay
        if maskKirmizi(i,j)
            yukari = 0; sol = 0;
            if i > 1, yukari = etiketler(i-1, j); end
            if j > 1, sol   = etiketler(i, j-1); end
            if yukari == 0 && sol == 0
                nesneAdedi = nesneAdedi + 1;
                etiketler(i,j) = nesneAdedi;
            elseif yukari == 0
                etiketler(i,j) = sol;
            elseif sol == 0
                etiketler(i,j) = yukari;
            else
                etiketler(i,j) = min(yukari, sol);
                etiketler(etiketler == max(yukari,sol)) = min(yukari,sol);
                nesneAdedi = max(etiketler(:));
            end
        end
    end
end

imgKutular = img;
subplot(2, 3, 5);
imshow(imgKutular);
hold on;

minAlan = 500;
sayac = 0;
for k = 1:nesneAdedi
    [satirlar, sutunlar] = find(etiketler == k);
    if numel(satirlar) > minAlan
        sayac = sayac + 1;
        minR = min(satirlar); maxR = max(satirlar);
        minC = min(sutunlar); maxC = max(sutunlar);
        cx = mean(sutunlar);
        cy = mean(satirlar);
        rectangle('Position', [minC, minR, maxC-minC, maxR-minR], ...
                  'EdgeColor', 'yellow', 'LineWidth', 2.5);
        text(cx, cy, num2str(sayac), ...
             'Color', 'white', 'FontSize', 14, 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center', ...
             'BackgroundColor', [0.8 0 0]);
    end
end
hold off;
title(sprintf('5) Tespit Edilen Nesneler: %d', sayac), ...
      'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 6. BÖLÜM: Orijinal + Maske Üst Üste (Overlay)
% ---------------------------------------------------------
subplot(2, 3, 6);
overlay = img;
mask3Doverlay = repmat(maskKirmizi, [1 1 3]);
overlay(mask3Doverlay) = uint8(double(img(mask3Doverlay)) * 0.5 + 127);
imshow(overlay);
title('6) Orijinal + Maske Örtüşmesi', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% KONSOL ÇIKTISI
% ---------------------------------------------------------
fprintf('\n========================================\n');
fprintf('  RENK FİLTRELEME SONUÇLARI\n');
fprintf('========================================\n');
fprintf('  Görsel boyutu     : %d x %d piksel\n', size(img,1), size(img,2));
fprintf('  Toplam kırmızı px : %d\n', sum(maskKirmizi(:)));
fprintf('  Tespit edilen nesne: %d adet\n', sayac);
fprintf('========================================\n\n');

% ---------------------------------------------------------
% BONUS: Sonucu kaydet (isteğe bağlı)
% ---------------------------------------------------------
% imwrite(imgFiltrelenmis, 'sonuc_filtrelenmis.png');
% imwrite(imgKutular,      'sonuc_kutular.png');
% fprintf('Görseller kaydedildi.\n');