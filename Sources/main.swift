import Cocoa
import WebKit

// Native UserScript: Ad-Free, Auto 4K/1080p, Zero-Border Cinema, Auto-Next Video, Scroll/Arrow Video Switching (FikFap Experience)
let injectedScript = """
(function() {
    'use strict';
    // 仅在 youtube.com 域名执行，绝对不污染 accounts.google.com 登录页面
    if (!window.location.hostname.includes('youtube.com')) {
        return;
    }
    console.log('[YouTube Native App] Zero-Border Cinema Engine Active');

    // 1. 注入强力清除广告、彻底干掉右侧滚动条灰边、100% 满幅无黑边影院 CSS
    const style = document.createElement('style');
    style.id = 'yt-native-clean-styles';
    style.textContent = `
        /* 1. 彻底清除所有横幅广告、推广位、推荐赞助 */
        ytd-promoted-video-renderer,
        ytd-display-ad-renderer,
        ytd-banner-promo-renderer,
        #player-ads,
        .ytp-ad-module,
        .ytp-ad-overlay-container,
        #masthead-ad,
        .ytd-ad-slot-renderer,
        ytd-statement-banner-renderer,
        ytd-in-feed-ad-layout-renderer,
        ytd-player-legacy-desktop-watch-ads-renderer,
        #panels ytd-ads-engagement-panel-content-renderer,
        ytd-action-companion-ad-renderer,
        tp-yt-paper-dialog:has(#feedback),
        .ytp-suggested-action-badge {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            pointer-events: none !important;
            height: 0 !important;
            max-height: 0 !important;
            overflow: hidden !important;
        }

        /* 2. 彻底消灭右侧滚动条与灰边 (Zero Scrollbar Track) */
        ::-webkit-scrollbar {
            display: none !important;
            width: 0px !important;
            height: 0px !important;
            background: transparent !important;
        }

        ::-webkit-scrollbar-thumb,
        ::-webkit-scrollbar-track,
        ::-webkit-scrollbar-corner {
            display: none !important;
            background: transparent !important;
        }

        html, body, ytd-app, #page-manager, ytd-watch-flexy, #columns, #primary {
            scrollbar-width: none !important;
            -ms-overflow-style: none !important;
        }

        body.cinema-mode-active,
        body.cinema-mode-active html,
        body.cinema-mode-active ytd-app,
        body.cinema-mode-active #page-manager {
            overflow: hidden !important;
            overflow-y: hidden !important;
            overflow-x: hidden !important;
        }

        /* 3. 首页顶部标题栏留出 28px 原生拖拽区 */
        #masthead-container {
            padding-top: 28px !important;
            background-color: rgba(15, 15, 15, 0.95) !important;
            backdrop-filter: blur(20px) !important;
            -webkit-backdrop-filter: blur(20px) !important;
            transition: opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1), transform 0.3s ease !important;
        }

        #page-manager {
            margin-top: 84px !important;
        }

        /* 4. 彻底消除上下左右所有黑边：100% 满幅无边框影院填充 */
        body.cinema-mode-active #masthead-container {
            display: none !important;
        }

        body.cinema-mode-active ytd-watch-flexy #player-theater-container,
        body.cinema-mode-active ytd-watch-flexy #full-bleed-container,
        body.cinema-mode-active ytd-watch-flexy #player-container-outer,
        body.cinema-mode-active ytd-watch-flexy #player-container-inner,
        body.cinema-mode-active ytd-watch-flexy #player-container,
        body.cinema-mode-active ytd-watch-flexy #player,
        body.cinema-mode-active ytd-watch-flexy ytd-player,
        body.cinema-mode-active #ytd-player,
        body.cinema-mode-active #container.ytd-player,
        body.cinema-mode-active #movie_player,
        body.cinema-mode-active .html5-video-player,
        body.cinema-mode-active .html5-video-container {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            right: 0 !important;
            bottom: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            max-width: 100vw !important;
            max-height: 100vh !important;
            min-height: 100vh !important;
            min-width: 100vw !important;
            margin: 0 !important;
            padding: 0 !important;
            border: none !important;
            z-index: 1000 !important;
            background: #000000 !important;
            overflow: hidden !important;
        }

        /* 视频本身在全屏与窗口下永远保持完美 16:9 比例，不拉伸、不裁切任何画面与字幕 */
        body.cinema-mode-active video.html5-main-video,
        body.cinema-mode-active video {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            right: 0 !important;
            bottom: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            max-width: 100vw !important;
            max-height: 100vh !important;
            min-width: 100vw !important;
            min-height: 100vh !important;
            margin: auto !important;
            padding: 0 !important;
            border: none !important;
            object-fit: contain !important;
            transform: none !important;
        }

        /* 控制栏贴合底部，增加平滑渐隐 */
        body.cinema-mode-active .ytp-chrome-bottom {
            width: calc(100% - 24px) !important;
            left: 12px !important;
            bottom: 8px !important;
            transition: opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1) !important;
        }

        body.cinema-mode-active .ytp-chrome-top,
        body.cinema-mode-active .ytp-gradient-bottom,
        body.cinema-mode-active .ytp-gradient-top {
            transition: opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1) !important;
        }

        /* 静止 2.5s 后播放器控件与顶部覆盖层自动平滑渐隐 */
        body.cinema-playing .ytp-chrome-bottom,
        body.cinema-playing .ytp-chrome-top,
        body.cinema-playing .ytp-gradient-bottom,
        body.cinema-playing .ytp-gradient-top {
            opacity: 0 !important;
            pointer-events: none !important;
        }

        body.cinema-active .ytp-chrome-bottom,
        body.cinema-active .ytp-chrome-top,
        body.cinema-active .ytp-gradient-bottom,
        body.cinema-active .ytp-gradient-top {
            opacity: 1 !important;
            pointer-events: auto !important;
        }

        body.hide-cursor,
        body.hide-cursor * {
            cursor: none !important;
        }

        /* 纯黑背景背景增强观影沉浸感 */
        ytd-app,
        #page-manager,
        ytd-watch-flexy {
            background-color: #000000 !important;
        }

        /* 5. 原生浮动按钮 (返回按钮与视图切换) */
        #yt-native-back-btn,
        #yt-native-toggle-btn {
            display: none;
            position: fixed;
            z-index: 999999;
            padding: 7px 15px;
            background: rgba(20, 20, 25, 0.85);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 20px;
            color: #ffffff;
            font-size: 13px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.3s ease, background 0.2s ease, transform 0.15s ease;
            user-select: none;
            -webkit-user-select: none;
            box-shadow: 0 4px 16px rgba(0,0,0,0.5);
        }

        #yt-native-back-btn {
            top: 14px;
            left: 82px;
        }

        #yt-native-toggle-btn {
            top: 14px;
            right: 20px;
        }

        #yt-native-back-btn:hover,
        #yt-native-toggle-btn:hover {
            background: rgba(255, 255, 255, 0.25);
            transform: scale(1.04);
        }

        body.cinema-mode-active.cinema-active #yt-native-back-btn,
        body.cinema-mode-active.cinema-active #yt-native-toggle-btn {
            display: block !important;
            opacity: 1 !important;
            pointer-events: auto !important;
        }

        body.cinema-playing #yt-native-back-btn,
        body.cinema-playing #yt-native-toggle-btn {
            opacity: 0 !important;
            pointer-events: none !important;
        }

        /* 6. 切视频 HUD 提示 Toast */
        #yt-native-toast {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%) scale(0.88);
            background: rgba(12, 12, 16, 0.85);
            color: #ffffff;
            padding: 14px 28px;
            border-radius: 30px;
            font-size: 16px;
            font-weight: 600;
            letter-spacing: 0.5px;
            backdrop-filter: blur(25px);
            -webkit-backdrop-filter: blur(25px);
            border: 1px solid rgba(255, 255, 255, 0.25);
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            pointer-events: none;
            z-index: 1000000;
            opacity: 0;
            transition: opacity 0.2s ease, transform 0.2s ease;
        }

        #yt-native-toast.visible {
            opacity: 1;
            transform: translate(-50%, -50%) scale(1);
        }
    `;
    (document.head || document.documentElement).appendChild(style);

    // 2. 切视频 HUD 浮层提示
    function showToast(text) {
        let toast = document.getElementById('yt-native-toast');
        if (!toast) {
            toast = document.createElement('div');
            toast.id = 'yt-native-toast';
            document.body.appendChild(toast);
        }
        toast.textContent = text;
        toast.classList.add('visible');
        clearTimeout(window._toastTimer);
        window._toastTimer = setTimeout(() => {
            toast.classList.remove('visible');
        }, 900);
    }

    // 3. 强力“下一个视频”与“上一个视频”调度引擎
    function playNextVideo() {
        console.log('[CinemaEngine] Advancing to next video...');
        const player = document.getElementById('movie_player');

        // 1. 尝试播放器的 nextVideo 原生接口
        if (player && typeof player.nextVideo === 'function') {
            try {
                player.nextVideo();
                return;
            } catch(e) {}
        }

        // 2. 尝试点击原生 Next 按钮 (Shift+N)
        const nextBtn = document.querySelector('.ytp-next-button') || document.querySelector('a.ytp-next-button');
        if (nextBtn && !nextBtn.hasAttribute('aria-disabled')) {
            nextBtn.click();
            return;
        }

        // 3. 抓取右侧推荐流的第一条视频跳转
        const nextSelectors = [
            'ytd-compact-video-renderer a#thumbnail',
            'ytd-watch-next-secondary-results-renderer ytd-compact-video-renderer a#thumbnail',
            '#secondary ytd-compact-video-renderer a#thumbnail',
            'ytd-item-section-renderer ytd-compact-video-renderer a#thumbnail'
        ];

        for (const sel of nextSelectors) {
            const link = document.querySelector(sel);
            if (link && link.href && !link.href.includes(window.location.search)) {
                link.click();
                return;
            }
        }

        // 4. 发送 Shift+N 快捷键
        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'N', code: 'KeyN', shiftKey: true, bubbles: true }));
    }

    function playPreviousVideo() {
        console.log('[CinemaEngine] Returning to previous video...');
        const player = document.getElementById('movie_player');
        if (player && typeof player.previousVideo === 'function') {
            try {
                player.previousVideo();
                return;
            } catch(e) {}
        }

        const prevBtn = document.querySelector('.ytp-prev-button');
        if (prevBtn && !prevBtn.hasAttribute('aria-disabled')) {
            prevBtn.click();
            return;
        }

        if (window.history.length > 1) {
            window.history.back();
        }
    }

    // 4. 播完后自动切换下一个视频 (Auto Next on Ended)
    function setupAutoPlayNext() {
        // 自动开启 YouTube 原生自动连播开关
        const autoNavBtn = document.querySelector('.ytp-autonav-toggle-button');
        if (autoNavBtn && autoNavBtn.getAttribute('aria-checked') === 'false') {
            autoNavBtn.click();
        }

        // 绑定 HTML5 video 的自然播放结束事件
        const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
        if (video && !video._nativeEndedBound) {
            video._nativeEndedBound = true;
            video.addEventListener('ended', () => {
                console.log('[AutoPlay] Video ended naturally, advancing to next video...');
                showToast('⏭ 播放完毕，正在切换下一个视频');
                setTimeout(playNextVideo, 800);
            });
        }
    }

    // 5. 强力视频贴片广告秒跳引擎
    function skipVideoAds() {
        const player = document.getElementById('movie_player') || document.querySelector('.html5-video-player');
        if (!player) return;

        const isAdShowing = player.classList.contains('ad-showing') ||
                            player.classList.contains('ad-interrupting') ||
                            Boolean(document.querySelector('.ytp-ad-player-overlay'));

        if (isAdShowing) {
            const video = player.querySelector('video') || document.querySelector('video');
            if (video) {
                video.muted = true;
                video.playbackRate = 16.0;
                if (video.duration && isFinite(video.duration) && video.currentTime < video.duration - 0.1) {
                    video.currentTime = video.duration;
                }
            }

            // 自动点击各种跳过广告按钮
            const skipSelectors = [
                '.ytp-ad-skip-button',
                '.ytp-ad-skip-button-modern',
                '.ytp-skip-ad-button',
                'button.ytp-ad-skip-button-icon',
                '.ytp-ad-overlay-close-button',
                'button[class*="skip"]'
            ];

            for (const sel of skipSelectors) {
                const btn = document.querySelector(sel);
                if (btn && typeof btn.click === 'function') {
                    btn.click();
                    break;
                }
            }
        }
    }

    // 6. 自动锁定最高分辨率画质 (4K / 1440p / 1080p 60fps)
    const qualityRank = {
        'highres': 100,
        'hd2880': 90,
        'hd2160': 80, // 4K
        'hd1440': 70, // 2K
        'hd1080': 60, // 1080p
        'hd720': 50,  // 720p
        'large': 40,  // 480p
        'medium': 30, // 360p
        'small': 20,  // 240p
        'tiny': 10    // 144p
    };

    let lastQualityLockedVideo = '';
    function lockMaxResolution() {
        const player = document.getElementById('movie_player');
        if (!player || typeof player.getAvailableQualityLevels !== 'function') return;

        const currentVideoId = player.getVideoData ? (player.getVideoData().video_id || '') : '';
        if (currentVideoId && currentVideoId === lastQualityLockedVideo) {
            return;
        }

        const levels = player.getAvailableQualityLevels();
        if (levels && levels.length > 0) {
            let bestQuality = levels[0];
            let bestScore = qualityRank[bestQuality] || 0;

            for (const lvl of levels) {
                const score = qualityRank[lvl] || 0;
                if (score > bestScore) {
                    bestScore = score;
                    bestQuality = lvl;
                }
            }

            try {
                if (typeof player.setPlaybackQualityRange === 'function') {
                    player.setPlaybackQualityRange(bestQuality, bestQuality);
                }
                if (typeof player.setPlaybackQuality === 'function') {
                    player.setPlaybackQuality(bestQuality);
                }
                lastQualityLockedVideo = currentVideoId;
                console.log('[MaxQuality] Locked YouTube video to highest available quality:', bestQuality);
            } catch(e) {}
        }
    }

    // 7. 强制视频元素无黑边、无滚动条铺满视口
    function fitVideoToWindow() {
        if (!window.location.pathname.includes('/watch') || !isCinemaModeEnabled) return;

        document.documentElement.style.setProperty('overflow', 'hidden', 'important');
        document.body.style.setProperty('overflow', 'hidden', 'important');

        const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
        if (video) {
            video.style.setProperty('position', 'fixed', 'important');
            video.style.setProperty('top', '0px', 'important');
            video.style.setProperty('left', '0px', 'important');
            video.style.setProperty('right', '0px', 'important');
            video.style.setProperty('bottom', '0px', 'important');
            video.style.setProperty('width', '100vw', 'important');
            video.style.setProperty('height', '100vh', 'important');
            video.style.setProperty('max-width', '100vw', 'important');
            video.style.setProperty('max-height', '100vh', 'important');
            video.style.setProperty('margin', 'auto', 'important');
            video.style.setProperty('object-fit', 'contain', 'important');
            video.style.setProperty('transform', 'none', 'important');
        }

        const player = document.getElementById('movie_player');
        if (player) {
            player.style.setProperty('position', 'fixed', 'important');
            player.style.setProperty('top', '0px', 'important');
            player.style.setProperty('left', '0px', 'important');
            player.style.setProperty('width', '100vw', 'important');
            player.style.setProperty('height', '100vh', 'important');
            player.style.setProperty('z-index', '1000', 'important');
        }
    }

    // 8. 浮动返回与模式切换按钮创建
    function ensureOverlayButtons() {
        let backBtn = document.getElementById('yt-native-back-btn');
        if (!backBtn) {
            backBtn = document.createElement('button');
            backBtn.id = 'yt-native-back-btn';
            backBtn.innerHTML = '‹ 返回首页';
            backBtn.title = '返回首页 (快捷键 Esc)';
            backBtn.onclick = function() {
                if (window.history.length > 1) {
                    window.history.back();
                } else {
                    window.location.href = 'https://www.youtube.com';
                }
            };
            document.body.appendChild(backBtn);
        }

        let toggleBtn = document.getElementById('yt-native-toggle-btn');
        if (!toggleBtn) {
            toggleBtn = document.createElement('button');
            toggleBtn.id = 'yt-native-toggle-btn';
            toggleBtn.innerHTML = '💬 展开评论与推荐';
            toggleBtn.title = '切换影院满屏 / 标准详情 (快捷键 W)';
            toggleBtn.onclick = function() {
                toggleCinemaMode();
            };
            document.body.appendChild(toggleBtn);
        }
    }

    let isCinemaModeEnabled = true;
    function toggleCinemaMode() {
        isCinemaModeEnabled = !isCinemaModeEnabled;
        const toggleBtn = document.getElementById('yt-native-toggle-btn');
        if (isCinemaModeEnabled) {
            document.body.classList.add('cinema-mode-active');
            if (toggleBtn) toggleBtn.innerHTML = '💬 展开评论与推荐';
            fitVideoToWindow();
        } else {
            document.body.classList.remove('cinema-mode-active');
            document.body.classList.remove('cinema-playing');
            document.body.classList.remove('hide-cursor');
            document.documentElement.style.removeProperty('overflow');
            document.body.style.removeProperty('overflow');
            if (toggleBtn) toggleBtn.innerHTML = '🎬 影院满幅';
            const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
            if (video) {
                video.style.removeProperty('position');
                video.style.removeProperty('top');
                video.style.removeProperty('left');
                video.style.removeProperty('width');
                video.style.removeProperty('height');
                video.style.removeProperty('object-fit');
            }
        }
    }

    function ensureTheaterMode() {
        const watchFlexy = document.querySelector('ytd-watch-flexy');
        if (!watchFlexy) return;
        if (!watchFlexy.hasAttribute('theater')) {
            const theaterBtn = document.querySelector('button.ytp-size-button');
            if (theaterBtn) {
                theaterBtn.click();
            }
        }
    }

    // 9. 监听路由与播放状态更新
    function updateWatchState() {
        const isWatch = window.location.pathname.includes('/watch');
        if (isWatch) {
            if (isCinemaModeEnabled) {
                document.body.classList.add('cinema-mode-active');
                document.body.classList.add('cinema-active');
                fitVideoToWindow();
            }
            ensureOverlayButtons();
            ensureTheaterMode();
            setupAutoPlayNext();
            lockMaxResolution();
            skipVideoAds();
        } else {
            document.body.classList.remove('cinema-mode-active');
            document.body.classList.remove('cinema-playing');
            document.body.classList.remove('cinema-active');
            document.body.classList.remove('hide-cursor');
            document.documentElement.style.removeProperty('overflow');
            document.body.style.removeProperty('overflow');
        }
    }

    // 10. 沉浸式隐显交互控制 (鼠标静止 2.5s 自动淡出)
    let cinemaTimer = null;
    function handleUserActivity() {
        document.body.classList.remove('cinema-playing');
        document.body.classList.add('cinema-active');
        document.body.classList.remove('hide-cursor');

        if (cinemaTimer) clearTimeout(cinemaTimer);

        cinemaTimer = setTimeout(() => {
            const isWatchPage = window.location.pathname.includes('/watch');
            const video = document.querySelector('video');
            const isPlaying = video && !video.paused && video.currentTime > 0;

            if (isWatchPage && isPlaying && document.body.classList.contains('cinema-mode-active')) {
                document.body.classList.remove('cinema-active');
                document.body.classList.add('cinema-playing');
                document.body.classList.add('hide-cursor');
            }
        }, 2500);
    }

    window.addEventListener('mousemove', handleUserActivity, { passive: true });
    window.addEventListener('mousedown', handleUserActivity, { passive: true });
    window.addEventListener('click', handleUserActivity, { passive: true });
    window.addEventListener('resize', fitVideoToWindow);

    // 11. 鼠标滚轮/触控板滑动换视频 (类似 FikFap 体验)
    let wheelDelta = 0;
    let wheelCooldown = false;

    window.addEventListener('wheel', (e) => {
        handleUserActivity();
        if (!window.location.pathname.includes('/watch') || !isCinemaModeEnabled) return;
        if (wheelCooldown) return;

        wheelDelta += e.deltaY;

        // 鼠标向下滑动 -> 切换下一个视频
        if (wheelDelta > 75) {
            wheelCooldown = true;
            wheelDelta = 0;
            showToast('⏭ 下一个视频');
            playNextVideo();
            setTimeout(() => { wheelCooldown = false; }, 1200);
        }
        // 鼠标向上滑动 -> 切换上一个视频
        else if (wheelDelta < -75) {
            wheelCooldown = true;
            wheelDelta = 0;
            showToast('⏮ 上一个视频');
            playPreviousVideo();
            setTimeout(() => { wheelCooldown = false; }, 1200);
        }

        clearTimeout(window._wheelResetTimer);
        window._wheelResetTimer = setTimeout(() => { wheelDelta = 0; }, 300);
    }, { passive: true });

    // 12. 全局周期性轮询与页面切歌监听
    setInterval(() => {
        skipVideoAds();
        lockMaxResolution();
        setupAutoPlayNext();
        updateWatchState();
        fitVideoToWindow();
    }, 400);

    window.addEventListener('yt-navigate-finish', () => {
        lastQualityLockedVideo = '';
        setTimeout(updateWatchState, 300);
        setTimeout(fitVideoToWindow, 500);
        setTimeout(setupAutoPlayNext, 600);
        setTimeout(lockMaxResolution, 600);
        setTimeout(skipVideoAds, 300);
    });

    window.addEventListener('popstate', updateWatchState);

    // 13. 全局键盘快捷键控制：向下键/向上键秒切视频
    window.addEventListener('keydown', (e) => {
        const tag = (e.target && e.target.tagName) ? e.target.tagName.toLowerCase() : '';
        if (tag === 'input' || tag === 'textarea' || (e.target && e.target.isContentEditable)) {
            return;
        }

        handleUserActivity();

        // 向下键 或 PageDown -> 下一个视频
        if (e.key === 'ArrowDown' || e.key === 'PageDown') {
            e.preventDefault();
            e.stopPropagation();
            showToast('⏭ 下一个视频');
            playNextVideo();
        }
        // 向上键 或 PageUp -> 上一个视频
        else if (e.key === 'ArrowUp' || e.key === 'PageUp') {
            e.preventDefault();
            e.stopPropagation();
            showToast('⏮ 上一个视频');
            playPreviousVideo();
        }
        else if (e.key === 'Escape') {
            if (window.location.pathname.includes('/watch')) {
                if (window.history.length > 1) {
                    window.history.back();
                } else {
                    window.location.href = 'https://www.youtube.com';
                }
            }
        } else if (e.key === 'w' || e.key === 'W') {
            toggleCinemaMode();
        } else if (e.key === 'f' || e.key === 'F') {
            const fsBtn = document.querySelector('button.ytp-fullscreen-button');
            if (fsBtn) {
                fsBtn.click();
            }
        }
    }, true);
})();
"""

// 顶部 28px 原生拖拽标题栏：避让左侧交通灯与浮动按钮，其余中间宽广区域支持拖动与双击全屏
class DraggableTitleBar: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // 0...80 留给红黄绿交通灯
        if point.x < 80 {
            return nil
        }
        // 80...220 留给左上角浮动返回按钮
        if point.x < 220 {
            return nil
        }
        // 右侧 200px 留给右上角展开按钮
        if point.x > (bounds.width - 200) {
            return nil
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            window?.toggleFullScreen(nil)
        } else {
            window?.performDrag(with: event)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var progressIndicator: NSProgressIndicator!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let targetURLString = "https://www.youtube.com"
        guard let url = URL(string: targetURLString) else { return }

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        // 默认 16:9 黄金分辨率比例：1280 × 720
        let defaultWidth: CGFloat = 1280
        let defaultHeight: CGFloat = 720
        let originX = screenFrame.midX - (defaultWidth / 2)
        let originY = screenFrame.midY - (defaultHeight / 2)
        let windowRect = NSRect(x: originX, y: originY, width: defaultWidth, height: defaultHeight)

        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.minSize = NSSize(width: 640, height: 360)
        // 锁定 16:9 黄金观影比例，彻底杜绝黑边
        window.aspectRatio = NSSize(width: 16, height: 9)
        // 启用原生全屏支持，支持绿灯按钮与 HTML5 网页全屏联动
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.black

        // WebKit 配置 (启用持久化 Cookie 数据存储)
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let userContentController = WKUserContentController()
        let userScript = WKUserScript(source: injectedScript, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(userScript)
        configuration.userContentController = userContentController

        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.allowsAirPlayForMediaPlayback = true

        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences

        if #available(macOS 12.3, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }

        webView = WKWebView(frame: windowRect, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true

        // 采用桌面版 Chrome User-Agent
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

        // 设置全黑底色，消除任何浅色边框与白屏眩光
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = NSColor.black
        }
        webView.setValue(false, forKey: "drawsBackground")

        // 顶部 2px 极简加载指示条
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0.0
        progressIndicator.maxValue = 1.0
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false

        // 顶部 28px 拖拽标题栏
        let draggableBar = DraggableTitleBar()
        draggableBar.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView(frame: windowRect)
        contentView.addSubview(webView)
        contentView.addSubview(draggableBar)
        contentView.addSubview(progressIndicator)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            draggableBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            draggableBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            draggableBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            draggableBar.heightAnchor.constraint(equalToConstant: 28),

            progressIndicator.topAnchor.constraint(equalTo: contentView.topAnchor),
            progressIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressIndicator.heightAnchor.constraint(equalToConstant: 2)
        ])

        window.contentView = contentView
        setupMainMenu()

        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)

        let request = URLRequest(url: url)
        webView.load(request)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress = webView.estimatedProgress
            progressIndicator.doubleValue = progress
            progressIndicator.isHidden = (progress >= 1.0)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - WKNavigationDelegate 导航与弹窗控制

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let targetURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let urlString = targetURL.absoluteString
        let scheme = (targetURL.scheme ?? "").lowercased()

        if urlString == "about:blank" || urlString.isEmpty {
            decisionHandler(.allow)
            return
        }

        if scheme != "http" && scheme != "https" {
            NSWorkspace.shared.open(targetURL)
            decisionHandler(.cancel)
            return
        }

        let host = (targetURL.host ?? "").lowercased()

        // YouTube 自身以及 Google 账号登录体系全部严格保留在当前原生客户端窗口运行
        let isInternalDomain = host.contains("youtube.com") ||
                               host.contains("youtu.be") ||
                               host.contains("google.com") ||
                               host.contains("googleusercontent.com") ||
                               host.contains("gstatic.com") ||
                               host.contains("googleapis.com")

        if isInternalDomain {
            // 如果网页使用 target="_blank" 或 window.open 打开新窗口，直接重定向在当前主窗口加载
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
            return
        }

        // 描述栏里的外部链接通过系统默认浏览器打开，不干扰客户端播放
        NSWorkspace.shared.open(targetURL)
        decisionHandler(.cancel)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            if let targetURL = navigationAction.request.url, targetURL.absoluteString != "about:blank" {
                webView.load(navigationAction.request)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            let host = url.host ?? ""
            if host.contains("myaccount.google.com") || (host.contains("accounts.google.com") && (url.path.contains("CheckCookie") || url.path.contains("b/0"))) {
                if let ytURL = URL(string: "https://www.youtube.com") {
                    webView.load(URLRequest(url: ytURL))
                }
            }
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled || nsError.code == 102 {
            return
        }
        print("[YouTubeApp] Provisional navigation error: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled || nsError.code == 102 {
            return
        }
        print("[YouTubeApp] Navigation error: \(error.localizedDescription)")
    }

    // MARK: - 原生菜单

    func setupMainMenu() {
        let mainMenu = NSMenu()

        // App Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About YouTube", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide YouTube", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit YouTube", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        fullScreenItem.target = self
        viewMenu.addItem(fullScreenItem)
        viewMenu.addItem(NSMenuItem.separator())

        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)
        let actualSizeItem = NSMenuItem(title: "Actual Size", action: #selector(actualSize), keyEquivalent: "0")
        actualSizeItem.target = self
        viewMenu.addItem(actualSizeItem)
        let zoomInItem = NSMenuItem(title: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+")
        zoomInItem.target = self
        viewMenu.addItem(zoomInItem)
        let zoomOutItem = NSMenuItem(title: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-")
        zoomOutItem.target = self
        viewMenu.addItem(zoomOutItem)
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // History Menu
        let historyMenuItem = NSMenuItem()
        let historyMenu = NSMenu(title: "History")
        let homeItem = NSMenuItem(title: "YouTube Home", action: #selector(goHome), keyEquivalent: "H")
        homeItem.keyEquivalentModifierMask = [.command, .shift]
        homeItem.target = self
        historyMenu.addItem(homeItem)
        let backItem = NSMenuItem(title: "Back", action: #selector(goBack), keyEquivalent: "[")
        backItem.target = self
        historyMenu.addItem(backItem)
        let forwardItem = NSMenuItem(title: "Forward", action: #selector(goForward), keyEquivalent: "]")
        forwardItem.target = self
        historyMenu.addItem(forwardItem)
        historyMenuItem.submenu = historyMenu
        mainMenu.addItem(historyMenuItem)

        // Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func toggleFullScreen() {
        window.toggleFullScreen(nil)
    }
    @objc func goHome() {
        if let url = URL(string: "https://www.youtube.com") {
            webView.load(URLRequest(url: url))
        }
    }
    @objc func reloadPage() { webView.reload() }
    @objc func actualSize() { webView.pageZoom = 1.0 }
    @objc func zoomIn() { webView.pageZoom += 0.1 }
    @objc func zoomOut() { webView.pageZoom = max(0.5, webView.pageZoom - 0.1) }
    @objc func goBack() { if webView.canGoBack { webView.goBack() } }
    @objc func goForward() { if webView.canGoForward { webView.goForward() } }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
