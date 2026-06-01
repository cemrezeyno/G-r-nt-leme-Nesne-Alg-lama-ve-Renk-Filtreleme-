% =========================================================
%  RENK FİLTRELEME VE NESNE ALGILAMA
%  Kullanım: renk_filtresi.m dosyasını MATLAB'da çalıştırın
%  Test görseli: peppers.png (MATLAB'ın yerleşik görseli)
% =========================================================

clc; clear; close all;

% ---------------------------------------------------------
% 1. BÖLÜM: Görseli Yükleme
% ---------------------------------------------------------
img = imread('peppers.png');

figure('Name', 'Renk Filtreleme ve Nesne Algilama', ...
       'NumberTitle', 'off', ...
       'Position', [100 100 1200 600]);

subplot(2, 3, 1);
imshow(img);
title('1) Orijinal Gorsel', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 2. BÖLÜM: RGB -> HSV Donusumu
% ---------------------------------------------------------
imgHSV = rgb2hsv(img);
H = imgHSV(:,:,1);
S = imgHSV(:,:,2);
V = imgHSV(:,:,3);

subplot(2, 3, 2);
imshow(H);
title('2) HSV - Ton (H) Kanali', 'FontWeight', 'bold', 'FontSize', 12);
colorbar;

% ---------------------------------------------------------
% 3. BÖLÜM: SIKI Kirmizi Maske
%    Sadece gercekten kirmizi pikseller: yuksek doygunluk,
%    yuksek parlaklik, dar H araligi
% ---------------------------------------------------------
maskH   = (H <= 0.06) | (H >= 0.92);   % dar kirmizi tonu
maskS   = (S >= 0.55);                  % soluk/pastel renkleri ele
maskV   = (V >= 0.30);                  % cok karanlik pikselleri ele

maskKirmizi = maskH & maskS & maskV;

% Kucuk govdeli morfoloji (sadece gurultu temizleme, birlestirme degil)
r = 3;
[gx, gy] = meshgrid(-r:r, -r:r);
se = double((gx.^2 + gy.^2) <= r^2);

% Once erozyon (gurultu sil), sonra dilatasyon (delikleri kapat)
eleman = sum(se(:));
maskKirmizi = conv2(double(maskKirmizi), se, 'same') >= eleman * 0.5;
maskKirmizi = conv2(double(maskKirmizi), se, 'same') > 0;

subplot(2, 3, 3);
imshow(maskKirmizi);
title('3) Ikili Maske (Kirmizi Alanlar)', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 4. BÖLÜM: Secici Renklendirme
% ---------------------------------------------------------
imgGri = repmat(rgb2gray(img), [1 1 3]);
imgFiltrelenmis = imgGri;
mask3D = repmat(maskKirmizi, [1 1 3]);
imgFiltrelenmis(mask3D) = img(mask3D);

subplot(2, 3, 4);
imshow(imgFiltrelenmis);
title('4) Secici Renklendirme', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 5. BÖLÜM: BFS ile Nesne Algılama - Her nesneye ayri kutu
% ---------------------------------------------------------
[satirSay, sutunSay] = size(maskKirmizi);
ziyaret = false(satirSay, sutunSay);

yon_r = [-1, 1,  0, 0];
yon_c = [ 0, 0, -1, 1];

minAlan = 800;        % kucuk gurultu noktalarini atla
nesne_kutular = [];

for br = 1:satirSay
    for bc = 1:sutunSay
        if maskKirmizi(br,bc) && ~ziyaret(br,bc)

            % BFS baslat
            kuyruk = zeros(satirSay*sutunSay, 2);
            kuyruk(1,:) = [br, bc];
            bas = 1; son = 1;
            ziyaret(br,bc) = true;

            piksel_r = zeros(1, satirSay*sutunSay);
            piksel_c = zeros(1, satirSay*sutunSay);
            piksel_r(1) = br;
            piksel_c(1) = bc;
            psay = 1;

            while bas <= son
                cr = kuyruk(bas,1);
                cc = kuyruk(bas,2);
                bas = bas + 1;

                for d = 1:4
                    nr = cr + yon_r(d);
                    nc = cc + yon_c(d);
                    if nr>=1 && nr<=satirSay && nc>=1 && nc<=sutunSay ...
                            && maskKirmizi(nr,nc) && ~ziyaret(nr,nc)
                        ziyaret(nr,nc) = true;
                        son = son + 1;
                        kuyruk(son,:) = [nr, nc];
                        psay = psay + 1;
                        piksel_r(psay) = nr;
                        piksel_c(psay) = nc;
                    end
                end
            end

            % Yeterince buyuk mu?
            if psay > minAlan
                pr = piksel_r(1:psay);
                pc = piksel_c(1:psay);
                nesne_kutular(end+1, :) = [min(pc), min(pr), max(pc), max(pr)]; %#ok
            end
        end
    end
end

% Kutu ciz
subplot(2, 3, 5);
imshow(img);
hold on;

[imgH_px, imgW_px, ~] = size(img);
sayac = size(nesne_kutular, 1);

for k = 1:sayac
    minC = max(1,        nesne_kutular(k,1) - 5);
    minR = max(1,        nesne_kutular(k,2) - 5);
    maxC = min(imgW_px,  nesne_kutular(k,3) + 5);
    maxR = min(imgH_px,  nesne_kutular(k,4) + 5);

    gen = maxC - minC;
    yuk = maxR - minR;
    cx  = minC + gen/2;
    cy  = minR + yuk/2;

    rectangle('Position', [minC, minR, gen, yuk], ...
              'EdgeColor', 'yellow', 'LineWidth', 2.5);

    text(cx, cy, num2str(k), ...
         'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', ...
         'BackgroundColor', [0.8 0 0]);
end
hold off;
title(sprintf('5) Tespit Edilen Kirmizi Nesneler: %d', sayac), ...
      'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% 6. BÖLÜM: Overlay
% ---------------------------------------------------------
subplot(2, 3, 6);
overlay = img;
mask3Dov = repmat(maskKirmizi, [1 1 3]);
overlay(mask3Dov) = uint8(double(img(mask3Dov)) * 0.5 + 127);
imshow(overlay);
title('6) Orijinal + Maske Ortusme', 'FontWeight', 'bold', 'FontSize', 12);

% ---------------------------------------------------------
% KONSOL CIKTISI
% ---------------------------------------------------------
fprintf('\n========================================\n');
fprintf('  RENK FILTRELEME SONUCLARI\n');
fprintf('========================================\n');
fprintf('  Gorsel boyutu      : %d x %d piksel\n', size(img,1), size(img,2));
fprintf('  Toplam kirmizi px  : %d\n', sum(maskKirmizi(:)));
fprintf('  Tespit edilen nesne: %d adet\n', sayac);
fprintf('========================================\n\n');