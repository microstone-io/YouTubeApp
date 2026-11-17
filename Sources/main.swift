import Cocoa
import WebKit
import IOKit.pwr_mgt

// Native UserScript:
// - Horizontal 16:9: Solidified v1.5.0 Clean Cinema Engine (Ad-Free, 16:9 Contain, Wheel/Arrow Nav, PiP, Auto-Next)
// - Vertical 9:16 (Shorts / Vertical Videos): Replicates FikFap Engine (9:16 Aspect Lock, Window Resize, 100% Cover Fill, Auto Advance)
let injectedScript = """
(function() {
    'use strict';
    // 仅在 youtube.com 域名执行，绝对不污染 accounts.google.com 登录页面
    if (!window.location.hostname.includes('youtube.com')) {
        return;
    }

    // 日志桥梁：将 JS 控制台日志实时同步至 Swift 及本地调试日志文件
    const origLog = console.log;
    const origWarn = console.warn;
    const origErr = console.error;
    function sendLog(lvl, args) {
        try {
            const str = Array.from(args).map(a => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' ');
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.youtubeBridge) {
                window.webkit.messageHandlers.youtubeBridge.postMessage({ action: 'log', level: lvl, text: str });
            }
        } catch(e) {}
    }
    console.log = function(...args) { origLog.apply(console, args); sendLog('INFO', args); };
    console.warn = function(...args) { origWarn.apply(console, args); sendLog('WARN', args); };
    console.error = function(...args) { origErr.apply(console, args); sendLog('ERR', args); };

    console.log('[YouTube Native App] Dual-Engine (16:9 Cinema + 9:16 FikFap Mode) Active');

    // 全局当前模式 (提前声明避免 TDZ 异常)
    var currentVideoMode = 'horizontal'; // 'horizontal' | 'vertical'

    // 0. 竖屏模式强制禁止 video loop 循环，让短视频能顺利触发自然播放结束 (复刻 FikFap 核心机制)
    try {
        const origLoopDescriptor = Object.getOwnPropertyDescriptor(HTMLVideoElement.prototype, 'loop');
        Object.defineProperty(HTMLVideoElement.prototype, 'loop', {
            get: function() {
                if (window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical') {
                    return false;
                }
                return origLoopDescriptor && origLoopDescriptor.get ? origLoopDescriptor.get.call(this) : false;
            },
            set: function(val) {
                if (window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical') {
                    return;
                }
                if (origLoopDescriptor && origLoopDescriptor.set) {
                    origLoopDescriptor.set.call(this, val);
                }
            },
            configurable: true
        });
    } catch(e) {}

    // 1. 注入强力清除广告、消除滚动条、16:9 与 9:16 双模式 CSS
    const style = document.createElement('style');
    style.id = 'yt-native-clean-styles';
    style.textContent = `
        /* 1. 彻底清除所有横幅广告、推广位、推荐赞助 (保留 .ytp-ad-module 以免跳过按钮失效) */
        ytd-promoted-video-renderer,
        ytd-display-ad-renderer,
        ytd-banner-promo-renderer,
        #player-ads,
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

        html, body, ytd-app, #page-manager, ytd-watch-flexy, ytd-shorts, #columns, #primary {
            scrollbar-width: none !important;
            -ms-overflow-style: none !important;
        }

        body.cinema-mode-active,
        body.cinema-vertical-mode,
        body.cinema-mode-active html,
        body.cinema-vertical-mode html,
        body.cinema-mode-active ytd-app,
        body.cinema-vertical-mode ytd-app {
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

        /* ============================================================ */
        /* 4. 横屏 16:9 影院模式 (固化 v1.5.0 模式) */
        /* ============================================================ */
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

        /* 横屏保持严格 16:9 比例居中 */
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

        /* ============================================================ */
        /* 5. 竖屏 9:16 FikFap 满幅模式 (Shorts / Vertical Videos) */
        /* ============================================================ */
        body.cinema-vertical-mode #masthead-container,
        body.cinema-vertical-mode ytd-mini-guide-renderer,
        body.cinema-vertical-mode #guide,
        body.cinema-vertical-mode #yt-native-toggle-btn {
            display: none !important;
            visibility: hidden !important;
            width: 0 !important;
            height: 0 !important;
            pointer-events: none !important;
        }

        /* 导航按钮透明置底并允许事件派发，确保点击切歌 100% 被 WebKit 响应 */
        body.cinema-vertical-mode #navigation-button-up,
        body.cinema-vertical-mode #navigation-button-down {
            opacity: 0 !important;
            visibility: visible !important;
            position: fixed !important;
            right: 12px !important;
            bottom: 12px !important;
            z-index: 1 !important;
        }

        /* 竖屏模式 CSS 变量全局覆盖：彻底根除因 calc((100vh - 96px)*0.5625) 与 mini-guide 导致的黑边 */
        :root,
        html,
        body,
        ytd-app,
        #content,
        #page-manager,
        ytd-shorts,
        #shorts-container,
        #shorts-inner-container {
            --ytd-mini-guide-width: 0px !important;
            --app-drawer-width: 0px !important;
            --ytd-shorts-player-width: 100vw !important;
            --ytd-shorts-player-height: 100vh !important;
        }

        /* 解决竖屏顶部空白、左侧 72px 边距与底部拉长问题：重置 page-manager 边距与所有容器 */
        body.cinema-vertical-mode html,
        body.cinema-vertical-mode body,
        body.cinema-vertical-mode ytd-app,
        body.cinema-vertical-mode ytd-app[mini-guide-visible] #page-manager,
        body.cinema-vertical-mode ytd-app #page-manager,
        body.cinema-vertical-mode #page-manager,
        body.cinema-vertical-mode #content,
        body.cinema-vertical-mode ytd-shorts,
        body.cinema-vertical-mode #shorts-container,
        body.cinema-vertical-mode #shorts-inner-container {
            margin: 0 !important;
            margin-left: 0 !important;
            margin-right: 0 !important;
            margin-top: 0 !important;
            margin-bottom: 0 !important;
            padding: 0 !important;
            padding-left: 0 !important;
            padding-right: 0 !important;
            padding-top: 0 !important;
            padding-bottom: 0 !important;
            left: 0 !important;
            right: 0 !important;
            top: 0 !important;
            bottom: 0 !important;
            width: 100vw !important;
            max-width: 100vw !important;
            overflow-x: hidden !important;
        }

        body.cinema-vertical-mode #shorts-container {
            height: 100vh !important;
            max-height: 100vh !important;
            scroll-snap-type: y mandatory !important;
            justify-content: flex-start !important;
            align-items: flex-start !important;
            overflow-y: scroll !important;
        }

        /* 彻底消除左边黑条、右侧黑边与底部下一个视频露头：解除每个 reel 卡片与所有内部容器的外边距与尺寸限制 */
        body.cinema-vertical-mode #shorts-inner-container {
            display: block !important;
            justify-content: flex-start !important;
            align-items: flex-start !important;
            margin: 0 !important;
            padding: 0 !important;
            width: 100vw !important;
        }

        body.cinema-vertical-mode #shorts-inner-container > div,
        body.cinema-vertical-mode #shorts-inner-container div[id],
        body.cinema-vertical-mode #reel-overlay-container,
        body.cinema-vertical-mode ytd-reel-video-renderer {
            margin: 0 !important;
            margin-left: 0 !important;
            margin-right: 0 !important;
            margin-top: 0 !important;
            margin-bottom: 0 !important;
            padding: 0 !important;
            width: 100vw !important;
            max-width: 100vw !important;
            min-width: 100vw !important;
            height: 100vh !important;
            max-height: 100vh !important;
            min-height: 100vh !important;
            left: 0 !important;
            right: 0 !important;
            top: 0 !important;
            bottom: 0 !important;
            scroll-snap-align: start !important;
            scroll-snap-stop: always !important;
            overflow: hidden !important;
        }

        /* 解决 2024-2026 YouTube 新版 #short-video-container 引入的 120px 底部黑块与 9:16 aspect-ratio 居中偏黑边 */
        body.cinema-vertical-mode #short-video-container,
        body.cinema-vertical-mode ytd-reel-video-renderer #short-video-container,
        body.cinema-vertical-mode #experiment-overlay,
        body.cinema-vertical-mode ytd-reel-video-renderer #experiment-overlay,
        body.cinema-vertical-mode ytd-reel-video-renderer #player-container,
        body.cinema-vertical-mode ytd-reel-video-renderer #player,
        body.cinema-vertical-mode ytd-reel-video-renderer #player-wrap,
        body.cinema-vertical-mode ytd-reel-video-renderer #player-api,
        body.cinema-vertical-mode ytd-reel-video-renderer #shorts-player,
        body.cinema-vertical-mode ytd-reel-video-renderer .html5-video-player,
        body.cinema-vertical-mode ytd-reel-video-renderer .html5-video-container,
        body.cinema-vertical-mode #player-container,
        body.cinema-vertical-mode #player,
        body.cinema-vertical-mode #shorts-player,
        body.cinema-vertical-mode .html5-video-player,
        body.cinema-vertical-mode .html5-video-container {
            margin: 0 !important;
            margin-left: 0 !important;
            margin-right: 0 !important;
            margin-top: 0 !important;
            margin-bottom: 0 !important;
            padding: 0 !important;
            width: 100vw !important;
            height: 100vh !important;
            max-width: 100vw !important;
            max-height: 100vh !important;
            min-width: 100vw !important;
            min-height: 100vh !important;
            aspect-ratio: auto !important;
            border-radius: 0 !important;
            left: 0 !important;
            right: 0 !important;
            top: 0 !important;
            bottom: 0 !important;
            background: transparent !important;
        }

        /* 竖屏视频 100% 满幅贴合 9:16 视口，无任何左、右、下黑边 */
        body.cinema-vertical-mode ytd-reel-video-renderer video,
        body.cinema-vertical-mode #shorts-player video,
        body.cinema-vertical-mode video.html5-main-video,
        body.cinema-vertical-mode video {
            position: absolute !important;
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
            object-fit: cover !important;
            border-radius: 0 !important;
            margin: 0 !important;
            padding: 0 !important;
            transform: none !important;
            z-index: 10 !important;
        }

        /* 竖屏交互控件 (点赞、评论、分享、转推、标题、频道、头像、声音等) 平滑显隐 */
        body.cinema-vertical-mode #experiment-overlay,
        body.cinema-vertical-mode .overlay,
        body.cinema-vertical-mode ytd-reel-player-overlay-renderer-cow,
        body.cinema-vertical-mode .ytdReelPlayerOverlayRendererHost,
        body.cinema-vertical-mode yt-reel-player-overlay-view-model,
        body.cinema-vertical-mode reel-action-bar-view-model,
        body.cinema-vertical-mode .ytReelPlayerOverlayViewModelActionsContainer,
        body.cinema-vertical-mode .ytReelPlayerOverlayViewModelMetadataContainer,
        body.cinema-vertical-mode .ytReelPlayerOverlayViewModelVerticalContainer,
        body.cinema-vertical-mode .ytReelPlayerOverlayViewModelHorizontalContainer,
        body.cinema-vertical-mode #actions,
        body.cinema-vertical-mode [id*="actions"],
        body.cinema-vertical-mode ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode .ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode ytd-reel-video-renderer #actions,
        body.cinema-vertical-mode ytd-reel-player-header-renderer,
        body.cinema-vertical-mode .ytd-reel-player-header-renderer,
        body.cinema-vertical-mode .ytp-chrome-top,
        body.cinema-vertical-mode .ytp-gradient-top,
        body.cinema-vertical-mode ytd-shorts-player-controls,
        body.cinema-vertical-mode #overlay,
        body.cinema-vertical-mode #yt-native-back-btn {
            transition: opacity 0.35s cubic-bezier(0.4, 0, 0.2, 1) !important;
            z-index: 9999 !important;
        }

        /* 竖屏沉浸播放状态 (无鼠标操作时完全隐匿所有按钮、头像、标题与交互元素) */
        body.cinema-vertical-mode.cinema-playing #experiment-overlay,
        body.cinema-vertical-mode.cinema-playing .overlay,
        body.cinema-vertical-mode.cinema-playing ytd-reel-player-overlay-renderer-cow,
        body.cinema-vertical-mode.cinema-playing .ytdReelPlayerOverlayRendererHost,
        body.cinema-vertical-mode.cinema-playing yt-reel-player-overlay-view-model,
        body.cinema-vertical-mode.cinema-playing reel-action-bar-view-model,
        body.cinema-vertical-mode.cinema-playing .ytReelPlayerOverlayViewModelActionsContainer,
        body.cinema-vertical-mode.cinema-playing .ytReelPlayerOverlayViewModelMetadataContainer,
        body.cinema-vertical-mode.cinema-playing .ytReelPlayerOverlayViewModelVerticalContainer,
        body.cinema-vertical-mode.cinema-playing .ytReelPlayerOverlayViewModelHorizontalContainer,
        body.cinema-vertical-mode.cinema-playing #actions,
        body.cinema-vertical-mode.cinema-playing [id*="actions"],
        body.cinema-vertical-mode.cinema-playing ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode.cinema-playing .ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode.cinema-playing ytd-reel-video-renderer #actions,
        body.cinema-vertical-mode.cinema-playing ytd-reel-player-header-renderer,
        body.cinema-vertical-mode.cinema-playing .ytd-reel-player-header-renderer,
        body.cinema-vertical-mode.cinema-playing .ytp-chrome-top,
        body.cinema-vertical-mode.cinema-playing .ytp-gradient-top,
        body.cinema-vertical-mode.cinema-playing ytd-shorts-player-controls,
        body.cinema-vertical-mode.cinema-playing #overlay,
        body.cinema-vertical-mode.cinema-playing #yt-native-back-btn {
            opacity: 0 !important;
            pointer-events: none !important;
            visibility: hidden !important;
        }

        /* 鼠标活动或操作时平滑浮现 */
        body.cinema-vertical-mode.cinema-active #experiment-overlay,
        body.cinema-vertical-mode.cinema-active .overlay,
        body.cinema-vertical-mode.cinema-active ytd-reel-player-overlay-renderer-cow,
        body.cinema-vertical-mode.cinema-active .ytdReelPlayerOverlayRendererHost,
        body.cinema-vertical-mode.cinema-active yt-reel-player-overlay-view-model,
        body.cinema-vertical-mode.cinema-active reel-action-bar-view-model,
        body.cinema-vertical-mode.cinema-active .ytReelPlayerOverlayViewModelActionsContainer,
        body.cinema-vertical-mode.cinema-active .ytReelPlayerOverlayViewModelMetadataContainer,
        body.cinema-vertical-mode.cinema-active .ytReelPlayerOverlayViewModelVerticalContainer,
        body.cinema-vertical-mode.cinema-active .ytReelPlayerOverlayViewModelHorizontalContainer,
        body.cinema-vertical-mode.cinema-active #actions,
        body.cinema-vertical-mode.cinema-active [id*="actions"],
        body.cinema-vertical-mode.cinema-active ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode.cinema-active .ytd-reel-player-overlay-renderer,
        body.cinema-vertical-mode.cinema-active ytd-reel-video-renderer #actions,
        body.cinema-vertical-mode.cinema-active ytd-reel-player-header-renderer,
        body.cinema-vertical-mode.cinema-active .ytd-reel-player-header-renderer,
        body.cinema-vertical-mode.cinema-active .ytp-chrome-top,
        body.cinema-vertical-mode.cinema-active .ytp-gradient-top,
        body.cinema-vertical-mode.cinema-active ytd-shorts-player-controls,
        body.cinema-vertical-mode.cinema-active #overlay,
        body.cinema-vertical-mode.cinema-active #yt-native-back-btn {
            opacity: 1 !important;
            pointer-events: auto !important;
            visibility: visible !important;
        }

        /* 6. 双模式共用：静止 2.5s 后播放器控件自动平滑渐隐 */
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

        ytd-app,
        #page-manager,
        ytd-watch-flexy,
        ytd-shorts {
            background-color: #000000 !important;
        }

        /* 7. 原生浮动按钮 (返回按钮与视图切换) */
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
        body.cinema-mode-active.cinema-active #yt-native-toggle-btn,
        body.cinema-vertical-mode.cinema-active #yt-native-back-btn {
            display: block !important;
            opacity: 1 !important;
            pointer-events: auto !important;
        }

        body.cinema-playing #yt-native-back-btn,
        body.cinema-playing #yt-native-toggle-btn {
            opacity: 0 !important;
            pointer-events: none !important;
        }

        /* 8. HUD 提示 Toast */
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

    // 3. 自动横竖屏侦测与 Swift 窗口比例同步
    // currentVideoMode 已在脚本头部全局声明

    function detectVideoOrientation() {
        let mode = 'horizontal';

        // 1. YouTube Shorts 页面或挂载了 Shorts 播放组件，100% 判定为 9:16 竖屏
        if (window.location.pathname.includes('/shorts') ||
            Boolean(document.querySelector('ytd-shorts[is-active]')) ||
            Boolean(document.querySelector('ytd-reel-video-renderer[is-active]'))) {
            mode = 'vertical';
        }
        // 2. 普通播放页通过视频宽高元数据动态判定
        else if (window.location.pathname.includes('/watch')) {
            const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
            if (video && video.videoWidth > 0 && video.videoHeight > 0) {
                if (video.videoHeight > video.videoWidth * 1.05) {
                    mode = 'vertical';
                } else {
                    mode = 'horizontal';
                }
            }
        } else {
            mode = 'horizontal';
        }

        if (mode !== currentVideoMode) {
            currentVideoMode = mode;
            console.log('[Orientation] Detected video orientation switch to:', mode);
            try {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.youtubeBridge) {
                    window.webkit.messageHandlers.youtubeBridge.postMessage({ action: 'setAspectRatio', mode: mode });
                }
            } catch(e) {}
        }

        return mode;
    }

    function hookVideoEvents() {
        const video = document.querySelector('video.html5-main-video') ||
                      document.querySelector('ytd-reel-video-renderer[is-active] video') ||
                      document.querySelector('video');
        if (video && !video._orientationHooked) {
            video._orientationHooked = true;
            video.addEventListener('loadedmetadata', detectVideoOrientation);
            video.addEventListener('canplay', detectVideoOrientation);
            video.addEventListener('playing', detectVideoOrientation);
        }
    }

    // 4. 强力“下一个视频”调度 (横屏与竖屏全场景自动分流)
    function playNextVideo() {
        if (window.location.pathname.includes('/shorts')) {
            playNextVerticalVideo();
            return;
        }

        console.log('[CinemaEngine] Advancing to next video...');
        const player = document.getElementById('movie_player') || document.getElementById('shorts-player');
        if (player && typeof player.nextVideo === 'function') {
            try { player.nextVideo(); return; } catch(e) {}
        }

        const nextBtn = document.querySelector('.ytp-next-button') || document.querySelector('a.ytp-next-button');
        if (nextBtn && !nextBtn.hasAttribute('aria-disabled')) {
            nextBtn.click();
            return;
        }

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

        window.dispatchEvent(new KeyboardEvent('keydown', { key: 'N', code: 'KeyN', shiftKey: true, bubbles: true }));
    }

    function playPreviousVideo() {
        if (window.location.pathname.includes('/shorts')) {
            playPrevVerticalVideo();
            return;
        }

        console.log('[CinemaEngine] Returning to previous video...');
        const player = document.getElementById('movie_player') || document.getElementById('shorts-player');
        if (player && typeof player.previousVideo === 'function') {
            try { player.previousVideo(); return; } catch(e) {}
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

    // 5. 播完后自动切换下一个视频 (普通播放页与通用连播)
    function setupAutoPlayNext() {
        const autoNavBtn = document.querySelector('.ytp-autonav-toggle-button');
        if (autoNavBtn && autoNavBtn.getAttribute('aria-checked') === 'false') {
            autoNavBtn.click();
        }

        const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
        if (video && !video._nativeEndedBound) {
            video._nativeEndedBound = true;
            video.addEventListener('ended', () => {
                console.log('[AutoPlay] Video ended naturally on watch page, advancing...');
                playNextVideo();
            });
        }
    }

    // 6. 查找视口中心当前正在播放的有效视频 (复刻 FikFap 视口几何定位)
    function getActiveVideo() {
        const activeReelVideo = document.querySelector('ytd-reel-video-renderer[is-active] video');
        if (activeReelVideo) return activeReelVideo;

        const videos = Array.from(document.querySelectorAll('video'));
        if (videos.length === 0) return null;
        if (videos.length === 1) return videos[0];

        const centerY = window.innerHeight / 2;
        for (const v of videos) {
            const rect = v.getBoundingClientRect();
            if (rect.top <= centerY && rect.bottom >= centerY && rect.height > 100) {
                return v;
            }
        }
        return videos.find(v => !v.paused && v.currentTime > 0) || videos[0] || null;
    }

    // 7. 竖屏专用下一个与上一个视频调度 (五维立体驱动：原生链接点击 + 官方按钮点击 + 容器卡片滚动 + JS 容器按键 + CoreGraphics 硬件按键)
    let isAdvanceLocked = false;
    let isAutoAdvancing = false;

    function playNextVerticalVideo() {
        if (isAdvanceLocked) return;
        isAdvanceLocked = true;
        setTimeout(() => { isAdvanceLocked = false; }, 2000);

        isAutoAdvancing = true;
        document.body.classList.remove('cinema-active');
        document.body.classList.add('cinema-playing');
        setTimeout(() => { isAutoAdvancing = false; }, 1800);

        console.log('[AutoPlay] Executing advance to next Short smoothly...');

        // 若当前在普通 /watch 播放页，直接使用 watch 页切歌机制
        if (!window.location.pathname.includes('/shorts')) {
            playNextVideo();
            return;
        }

        // 提取下一个视频信息供备用跳转与校验
        const ytdShorts = document.querySelector('ytd-shorts');
        let nextUrl = '';
        let nextVideoId = '';
        if (ytdShorts && ytdShorts.shortsProcessedSequence) {
            const seq = ytdShorts.shortsProcessedSequence;
            const curIdx = typeof ytdShorts.index === 'number' ? ytdShorts.index : 0;
            const nextItem = seq[curIdx + 1] || seq[1];
            if (nextItem) {
                nextVideoId = nextItem.videoId || nextItem.reelWatchEndpoint?.videoId || nextItem.command?.reelWatchEndpoint?.videoId || '';
                nextUrl = nextItem.command?.commandMetadata?.webCommandMetadata?.url || (nextVideoId ? '/shorts/' + nextVideoId : '');
            }
        }

        // 步骤 1: 优先触发 YouTube 原生丝滑滚动切片动画 (无闪烁、无重载、60fps 官方原生滑动)
        let advanced = false;
        if (ytdShorts && typeof ytdShorts.handleNextButtonClick === 'function') {
            try {
                ytdShorts.handleNextButtonClick({ type: 'click' });
                advanced = true;
            } catch(e) {}
        }

        function simulateClick(el) {
            if (!el) return;
            try {
                const opts = { bubbles: true, cancelable: true, view: window };
                el.dispatchEvent(new PointerEvent('pointerdown', opts));
                el.dispatchEvent(new MouseEvent('mousedown', opts));
                el.dispatchEvent(new PointerEvent('pointerup', opts));
                el.dispatchEvent(new MouseEvent('mouseup', opts));
                el.dispatchEvent(new MouseEvent('click', opts));
                if (typeof el.click === 'function') el.click();
            } catch(e) {}
        }

        // 步骤 2: 备用点击官方下翻按钮
        if (!advanced) {
            const nextBtn = document.querySelector('#navigation-button-down yt-button-shape button, #navigation-button-down button');
            if (nextBtn) {
                simulateClick(nextBtn);
                advanced = true;
            }
        }

        // 步骤 3: 确保新滑入的短视频流自动起播
        setTimeout(() => {
            const allV = Array.from(document.querySelectorAll('video'));
            for (const v of allV) {
                if (v.paused && v.duration > 0 && v.currentTime < 1.0) {
                    v.play().catch(() => {});
                }
            }
        }, 350);

        // 步骤 4: 终极保护性静默兜底 (仅在原生滑动在 1.4 秒内未能成功切换时才触发，正常情况下绝不触发，保障 100% 切换)
        if (nextUrl && nextVideoId) {
            const targetId = nextVideoId;
            const targetUrl = nextUrl;
            setTimeout(() => {
                if (!window.location.pathname.includes(targetId)) {
                    console.log('[AutoPlay] Fallback direct route navigation to:', targetUrl);
                    const navLink = document.createElement('a');
                    navLink.href = targetUrl;
                    navLink.style.display = 'none';
                    document.body.appendChild(navLink);
                    navLink.click();
                    setTimeout(() => { navLink.remove(); }, 100);
                }
            }, 1400);
        }
    }

    function playPrevVerticalVideo() {
        if (isAdvanceLocked) return;
        isAdvanceLocked = true;
        setTimeout(() => { isAdvanceLocked = false; }, 2000);

        isAutoAdvancing = true;
        document.body.classList.remove('cinema-active');
        document.body.classList.add('cinema-playing');
        setTimeout(() => { isAutoAdvancing = false; }, 1800);

        console.log('[AutoPlay] Returning to previous Short smoothly...');

        if (!window.location.pathname.includes('/shorts')) {
            playPreviousVideo();
            return;
        }

        const ytdShorts = document.querySelector('ytd-shorts');
        let advanced = false;
        if (ytdShorts && typeof ytdShorts.handlePrevButtonClick === 'function') {
            try {
                ytdShorts.handlePrevButtonClick({ type: 'click' });
                advanced = true;
            } catch(e) {}
        }

        if (!advanced) {
            const prevBtn = document.querySelector('#navigation-button-up yt-button-shape button, #navigation-button-up button');
            if (prevBtn && typeof prevBtn.click === 'function') {
                prevBtn.click();
            }
        }

        setTimeout(() => {
            const allV = Array.from(document.querySelectorAll('video'));
            for (const v of allV) {
                if (v.paused && v.duration > 0 && v.currentTime < 1.0) {
                    v.play().catch(() => {});
                }
            }
        }, 350);
    }

    // 8. 竖屏短视频播完自动切换下一条 (复刻 FikFap 铁壁中点门控机制，彻底杜绝黑屏秒切与不切死循环)
    let activeVideoId = '';
    let hasReachedMidpoint = false;
    let hasTriggeredEnd = false;
    let maxPlaybackProgress = 0;

    function checkShortsAutoPlay() {
        const isShorts = window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical';
        if (!isShorts) return;

        const video = getActiveVideo();
        if (!video) return;

        // 唯一视频流标识 (blob url 或 src 结合 pathname)
        const currentSrc = video.currentSrc || video.src || '';
        const currentId = (currentSrc ? currentSrc : 'video') + '::' + window.location.pathname;

        // 检测到新视频流接入时，彻底重置门控与状态
        if (currentId !== activeVideoId) {
            activeVideoId = currentId;
            hasReachedMidpoint = false;
            hasTriggeredEnd = false;
            maxPlaybackProgress = 0;
            console.log('[AutoPlay] Tracking new Short stream:', currentId);
            return;
        }

        // 若当前视频已触发过切换，或处于冷却锁定期，绝不重复触发
        if (hasTriggeredEnd || isAdvanceLocked) return;

        const duration = video.duration;
        const currentTime = video.currentTime;

        // 状态心跳日志（每 3 秒打印一次当前激活视频播放状态）
        if (!window._lastStateLog || Date.now() - window._lastStateLog > 3000) {
            window._lastStateLog = Date.now();
            console.log('[AutoPlay Status] cur: ' + (currentTime || 0).toFixed(1) + ' / ' + (duration || 0).toFixed(1) + ' paused: ' + video.paused);
        }

        // 视频时长必须已就绪且有效（大于 2 秒）
        if (!duration || isNaN(duration) || duration <= 2.0) return;

        // 正在播放中时持续记录最高进度
        if (!video.paused && currentTime > maxPlaybackProgress) {
            maxPlaybackProgress = currentTime;
        }

        // 步骤 1：视频必须实际播放超过 35% 时长才解锁中点门控（彻底杜绝黑屏秒切）
        if (maxPlaybackProgress >= duration * 0.35 && currentTime >= duration * 0.35) {
            if (!hasReachedMidpoint) {
                hasReachedMidpoint = true;
                console.log('[AutoPlay] Midpoint reached for:', window.location.pathname, 'progress:', maxPlaybackProgress.toFixed(1), 'dur:', duration.toFixed(1));
            }
        }

        // 步骤 2：仅当通过中点门控后，才允许判定放完或循环回滚
        if (hasReachedMidpoint) {
            const remaining = duration - currentTime;

            // 放完判定（绝不要求 !video.paused，因为放完或 loop 时 video.paused 按规范自动变为 true）：
            // 1. 距离结尾 <= 0.45 秒
            // 2. 原生 ended 状态
            // 3. 循环回滚：当前时间倒退回 1.2 秒以内，或比历史峰值倒退 2.5 秒以上
            const reachedEnd = (remaining <= 0.45 && remaining >= -1.0);
            const isEnded = Boolean(video.ended);
            const loopedBack = (currentTime < 1.2) || (currentTime < maxPlaybackProgress - 2.5);

            if (reachedEnd || isEnded || loopedBack) {
                hasTriggeredEnd = true;
                hasReachedMidpoint = false; // 立即重置门控，杜绝链式跳过
                console.log('[AutoPlay] Video completed! reachedEnd:', reachedEnd, 'isEnded:', isEnded, 'loopedBack:', loopedBack, 'cur:', currentTime.toFixed(2), 'dur:', duration.toFixed(2));
                
                // 深度打印当前所有 reel 状态
                const reels = Array.from(document.querySelectorAll('ytd-reel-video-renderer'));
                console.log('[AutoPlay Debug] Total reels:', reels.length);
                reels.forEach((r, idx) => {
                    const isAct = r.hasAttribute('is-active');
                    const link = r.querySelector('a[href*="/shorts/"]');
                    const href = link ? link.getAttribute('href') : 'none';
                    console.log('   Reel #' + idx, 'is-active:', isAct, 'id:', r.id, 'href:', href, 'top:', r.offsetTop, 'h:', r.offsetHeight);
                });

                // 深度探测 ytd-shorts 与 navigation-button-down 内部组件及接口
                const ytdShorts = document.querySelector('ytd-shorts');
                if (ytdShorts) {
                    const allKeys = Object.getOwnPropertyNames(ytdShorts).concat(Object.getOwnPropertyNames(Object.getPrototypeOf(ytdShorts)));
                    const interesting = allKeys.filter(k => typeof ytdShorts[k] === 'function');
                    console.log('[AutoPlay Introspection] ytdShorts functions:', interesting.slice(0, 30).join(', '));
                }

                const shortsPlayer = document.querySelector('#shorts-player') || document.querySelector('#movie_player');
                if (shortsPlayer) {
                    const pKeys = [];
                    for (let k in shortsPlayer) {
                        if (typeof shortsPlayer[k] === 'function' && (k.toLowerCase().includes('next') || k.toLowerCase().includes('load') || k.toLowerCase().includes('video'))) {
                            pKeys.push(k);
                        }
                    }
                    console.log('[AutoPlay Introspection] player methods:', pKeys.join(', '));
                }

                const navDown = document.querySelector('#navigation-button-down');
                if (navDown) {
                    console.log('[AutoPlay Introspection] navDown tag:', navDown.tagName, 'hidden:', navDown.hidden, 'offsetParent:', Boolean(navDown.offsetParent));
                    const innerBtn = navDown.querySelector('button');
                    console.log('[AutoPlay Introspection] innerBtn:', innerBtn ? innerBtn.outerHTML.slice(0, 200) : 'none');
                }

                playNextVerticalVideo();
            }
        }
    }

    // 8. 自动跳过确认弹窗与视频广告 (现代无感快进 + 静音，杜绝修改 currentTime 破坏 MediaSource 缓冲区致黑屏)
    function autoDismissContinueWatching() {
        const confirmSelectors = [
            'ytd-popup-container yt-confirm-dialog-renderer #confirm-button button',
            'ytd-popup-container yt-confirm-dialog-renderer #confirm-button',
            'tp-yt-paper-dialog #confirm-button button',
            'yt-button-shape#confirm-button button',
            'ytd-modal-with-title-and-button-renderer button#confirm-button',
            'yt-confirm-dialog-renderer button',
            '.ytp-pause-overlay .ytp-pause-overlay-container'
        ];
        for (const sel of confirmSelectors) {
            const btn = document.querySelector(sel);
            if (btn && typeof btn.click === 'function') {
                btn.click();
                const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
                if (video && video.paused && typeof video.play === 'function') {
                    video.play().catch(() => {});
                }
                break;
            }
        }
    }

    let isAdFastForwarding = false;
    let savedPlaybackRate = 1.0;

    function skipVideoAds() {
        const player = document.getElementById('movie_player') || document.querySelector('.html5-video-player');
        if (!player) return;

        const isAdShowing = player.classList.contains('ad-showing') ||
                            player.classList.contains('ad-interrupting') ||
                            Boolean(player.querySelector('.ytp-ad-player-overlay')) ||
                            Boolean(document.querySelector('.ytp-ad-text, .ytp-ad-preview-container, .ytp-ad-skip-button-container'));

        const video = player.querySelector('video') || document.querySelector('video.html5-main-video') || document.querySelector('video');

        if (isAdShowing) {
            // 1. 尝试直接点击跳过按钮
            const skipSelectors = [
                '.ytp-ad-skip-button',
                '.ytp-ad-skip-button-modern',
                '.ytp-skip-ad-button',
                'button.ytp-ad-skip-button-icon',
                '.ytp-ad-overlay-close-button',
                'button[class*="skip"]',
                '.ytp-ad-skip-button-text'
            ];

            for (const sel of skipSelectors) {
                const btn = document.querySelector(sel);
                if (btn && typeof btn.click === 'function') {
                    btn.click();
                    break;
                }
            }

            // 2. 对于中插广告，静音并拉满 16 倍速快速掠过
            // 严禁设置 video.currentTime = video.duration（会导致破坏 MediaSource 缓冲区致黑屏死锁或直接跳到正片结尾）
            if (video) {
                if (!isAdFastForwarding) {
                    isAdFastForwarding = true;
                    savedPlaybackRate = (video.playbackRate >= 0.25 && video.playbackRate <= 4.0) ? video.playbackRate : 1.0;
                }
                video.muted = true;
                video.playbackRate = 16.0;
                if (video.paused && typeof video.play === 'function') {
                    video.play().catch(() => {});
                }
            }
        } else {
            // 广告已经结束：立即无缝恢复原播放速度和声音
            if (isAdFastForwarding) {
                isAdFastForwarding = false;
                if (video) {
                    video.playbackRate = savedPlaybackRate || 1.0;
                    video.muted = false;
                    if (video.paused && typeof video.play === 'function') {
                        video.play().catch(() => {});
                    }
                }
            }
        }
    }

    // 播放健康看门狗：防止横屏影院模式下由于广告结束后的临时卡顿造成黑屏假死
    let lastPlayTime = -1;
    let stallCounter = 0;
    function checkPlaybackHealth() {
        if (currentVideoMode !== 'horizontal') return;
        const video = document.querySelector('video.html5-main-video') || document.querySelector('video');
        if (!video) return;

        const player = document.getElementById('movie_player');
        if (player && typeof player.getPlayerState === 'function') {
            const state = player.getPlayerState();
            // 1: playing, 3: buffering
            if (state === 3) {
                stallCounter++;
                if (stallCounter >= 25) { // 缓冲停滞超过 3 秒，尝试唤醒
                    stallCounter = 0;
                    if (video.paused && typeof video.play === 'function') {
                        video.play().catch(() => {});
                    }
                }
            } else if (state === 1) {
                stallCounter = 0;
            }
        }
    }

    // 9. 自动锁定最高分辨率画质
    const qualityRank = {
        'highres': 100,
        'hd2880': 90,
        'hd2160': 80,
        'hd1440': 70,
        'hd1080': 60,
        'hd720': 50,
        'large': 40,
        'medium': 30,
        'small': 20,
        'tiny': 10
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

    // 10. 视口铺满布局执行器 (横屏 contain / 竖屏 cover)
    function fitVideoToWindow() {
        if (!isCinemaModeEnabled) return;
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
            video.style.setProperty('object-fit', 'contain', 'important'); // 横屏严格 16:9 居中
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

    function fitVerticalVideo() {
        document.documentElement.style.setProperty('overflow', 'hidden', 'important');
        document.body.style.setProperty('overflow', 'hidden', 'important');

        // 覆盖 YouTube 内部 Shorts 动态宽度变量，彻底清除右侧与左侧黑边
        document.documentElement.style.setProperty('--ytd-mini-guide-width', '0px', 'important');
        document.documentElement.style.setProperty('--app-drawer-width', '0px', 'important');
        document.documentElement.style.setProperty('--ytd-shorts-player-width', '100vw', 'important');
        document.documentElement.style.setProperty('--ytd-shorts-player-height', '100vh', 'important');
        document.body.style.setProperty('--ytd-mini-guide-width', '0px', 'important');
        document.body.style.setProperty('--app-drawer-width', '0px', 'important');
        document.body.style.setProperty('--ytd-shorts-player-width', '100vw', 'important');
        document.body.style.setProperty('--ytd-shorts-player-height', '100vh', 'important');

        // 移除 ytd-app 上的 mini-guide-visible 属性，彻底消除桌面端 72px 左侧黑条
        const ytdApp = document.querySelector('ytd-app');
        if (ytdApp) {
            ytdApp.removeAttribute('mini-guide-visible');
        }

        // 强制重置 #page-manager 与 #content 的 margin-left / margin-top 为 0
        const pageManager = document.querySelector('#page-manager');
        if (pageManager) {
            pageManager.style.setProperty('margin', '0px', 'important');
            pageManager.style.setProperty('margin-left', '0px', 'important');
            pageManager.style.setProperty('margin-top', '0px', 'important');
            pageManager.style.setProperty('padding', '0px', 'important');
            pageManager.style.setProperty('width', '100vw', 'important');
            pageManager.style.setProperty('max-width', '100vw', 'important');
        }

        const content = document.querySelector('#content');
        if (content) {
            content.style.setProperty('margin', '0px', 'important');
            content.style.setProperty('margin-left', '0px', 'important');
            content.style.setProperty('margin-top', '0px', 'important');
            content.style.setProperty('padding', '0px', 'important');
        }

        // 隐藏侧栏与顶栏
        const navElements = document.querySelectorAll('ytd-mini-guide-renderer, #guide, #masthead-container');
        navElements.forEach(el => {
            el.style.setProperty('display', 'none', 'important');
            el.style.setProperty('width', '0px', 'important');
        });

        // 强力对齐页面上所有视频与容器，根除黑边
        const allVideos = Array.from(document.querySelectorAll('video'));
        allVideos.forEach(v => {
            v.style.setProperty('position', 'absolute', 'important');
            v.style.setProperty('top', '0px', 'important');
            v.style.setProperty('left', '0px', 'important');
            v.style.setProperty('right', '0px', 'important');
            v.style.setProperty('bottom', '0px', 'important');
            v.style.setProperty('width', '100vw', 'important');
            v.style.setProperty('height', '100vh', 'important');
            v.style.setProperty('max-width', '100vw', 'important');
            v.style.setProperty('max-height', '100vh', 'important');
            v.style.setProperty('min-width', '100vw', 'important');
            v.style.setProperty('min-height', '100vh', 'important');
            v.style.setProperty('object-fit', 'cover', 'important');
            v.style.setProperty('border-radius', '0px', 'important');
            v.style.setProperty('margin', '0px', 'important');
            v.style.setProperty('padding', '0px', 'important');
            v.style.setProperty('transform', 'none', 'important');
            v.style.setProperty('z-index', '10', 'important');
        });

        // 强制重置 virtual list 包装器 #shorts-inner-container > div (清除 26px 左右外边距与高度截断)
        const reelWrappers = document.querySelectorAll('#shorts-inner-container, #shorts-inner-container > div, #shorts-inner-container div[id], #reel-overlay-container, ytd-reel-video-renderer');
        reelWrappers.forEach(rw => {
            rw.style.setProperty('margin', '0px', 'important');
            rw.style.setProperty('margin-left', '0px', 'important');
            rw.style.setProperty('margin-right', '0px', 'important');
            rw.style.setProperty('margin-top', '0px', 'important');
            rw.style.setProperty('margin-bottom', '0px', 'important');
            rw.style.setProperty('padding', '0px', 'important');
            rw.style.setProperty('width', '100vw', 'important');
            rw.style.setProperty('height', '100vh', 'important');
            rw.style.setProperty('min-height', '100vh', 'important');
            rw.style.setProperty('max-height', '100vh', 'important');
            rw.style.setProperty('left', '0px', 'important');
            rw.style.setProperty('right', '0px', 'important');
            rw.style.setProperty('top', '0px', 'important');
            rw.style.setProperty('bottom', '0px', 'important');
        });

        const playerWrappers = document.querySelectorAll('#short-video-container, #experiment-overlay, #player, #player-wrap, #player-api, #shorts-player, #player-container, ytd-shorts, #shorts-container, #shorts-inner-container, .html5-video-player, .html5-video-container');
        playerWrappers.forEach(p => {
            p.style.setProperty('margin', '0px', 'important');
            p.style.setProperty('margin-left', '0px', 'important');
            p.style.setProperty('margin-right', '0px', 'important');
            p.style.setProperty('padding', '0px', 'important');
            p.style.setProperty('left', '0px', 'important');
            p.style.setProperty('right', '0px', 'important');
            p.style.setProperty('top', '0px', 'important');
            p.style.setProperty('bottom', '0px', 'important');
            p.style.setProperty('width', '100vw', 'important');
            p.style.setProperty('height', '100vh', 'important');
            p.style.setProperty('max-width', '100vw', 'important');
            p.style.setProperty('max-height', '100vh', 'important');
            p.style.setProperty('aspect-ratio', 'auto', 'important');
            p.style.setProperty('border-radius', '0px', 'important');
            p.style.setProperty('--ytd-shorts-player-width', '100vw', 'important');
            p.style.setProperty('--ytd-shorts-player-height', '100vh', 'important');
        });

        // 对齐当前激活的 reel 卡片到视口顶部，杜绝底部下一个视频画面露头
        const activeReel = document.querySelector('ytd-reel-video-renderer[is-active]');
        const shortsContainer = document.querySelector('#shorts-container');
        if (activeReel && shortsContainer) {
            const targetTop = activeReel.offsetTop;
            if (Math.abs(shortsContainer.scrollTop - targetTop) > 2) {
                shortsContainer.scrollTop = targetTop;
            }
        }

        if (shortsContainer) {
            shortsContainer.style.setProperty('justify-content', 'flex-start', 'important');
            shortsContainer.style.setProperty('align-items', 'flex-start', 'important');
            shortsContainer.style.setProperty('--ytd-shorts-player-width', '100vw', 'important');
            shortsContainer.style.setProperty('--ytd-shorts-player-height', '100vh', 'important');
            if (shortsContainer.scrollLeft !== 0) shortsContainer.scrollLeft = 0;
            if (!shortsContainer._scrollLocked) {
                shortsContainer._scrollLocked = true;
                shortsContainer.addEventListener('scroll', () => {
                    if (shortsContainer.scrollLeft !== 0) shortsContainer.scrollLeft = 0;
                }, { passive: true });
            }
        }

        const innerContainer = document.querySelector('#shorts-inner-container');
        if (innerContainer) {
            if (innerContainer.scrollLeft !== 0) innerContainer.scrollLeft = 0;
            if (!innerContainer._scrollLocked) {
                innerContainer._scrollLocked = true;
                innerContainer.addEventListener('scroll', () => {
                    if (innerContainer.scrollLeft !== 0) innerContainer.scrollLeft = 0;
                }, { passive: true });
            }
        }
    }

    // 11. 浮动返回与模式切换按钮创建
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

    // 12. 原生画中画切换 (PiP)
    function togglePictureInPicture() {
        const video = document.querySelector('ytd-reel-video-renderer[is-active] video') ||
                      document.querySelector('video.html5-main-video') ||
                      document.querySelector('video');
        if (!video) return;
        if (document.pictureInPictureElement) {
            document.exitPictureInPicture().catch(() => {});
            showToast('⏹ 已退出画中画');
        } else if (document.pictureInPictureEnabled) {
            video.requestPictureInPicture().then(() => {
                showToast('📺 已开启画中画小窗');
            }).catch(() => {});
        }
    }

    // 13. 播放倍速动态微调
    function adjustPlaybackSpeed(delta) {
        const video = document.querySelector('ytd-reel-video-renderer[is-active] video') ||
                      document.querySelector('video.html5-main-video') ||
                      document.querySelector('video');
        if (!video) return;
        let rate = Math.round((video.playbackRate + delta) * 100) / 100;
        rate = Math.max(0.5, Math.min(3.0, rate));
        video.playbackRate = rate;
        showToast('⚡ ' + rate.toFixed(2) + 'x 倍速');
    }

    function resetPlaybackSpeed() {
        const video = document.querySelector('ytd-reel-video-renderer[is-active] video') ||
                      document.querySelector('video.html5-main-video') ||
                      document.querySelector('video');
        if (!video) return;
        video.playbackRate = 1.0;
        showToast('⚡ 1.0x 正常倍速');
    }

    // 14. 路由状态机与横竖屏自动分流更新
    function updateWatchState() {
        const isShorts = window.location.pathname.includes('/shorts');
        const isWatch = window.location.pathname.includes('/watch');
        const mode = detectVideoOrientation();

        if (isShorts || (isWatch && mode === 'vertical')) {
            // === 9:16 竖屏模式：复制 FikFap 满幅与交互 ===
            document.body.classList.remove('cinema-mode-active');
            if (!document.body.classList.contains('cinema-vertical-mode')) {
                document.body.classList.add('cinema-vertical-mode');
                fitVerticalVideo();
            }
            if (!document.body.classList.contains('cinema-playing') && !document.body.classList.contains('cinema-active')) {
                document.body.classList.add('cinema-playing');
            }
            ensureOverlayButtons();
            checkShortsAutoPlay();
            skipVideoAds();
        } else if (isWatch && mode === 'horizontal') {
            // === 16:9 横屏模式：保持固化的 v1.5.0 影院逻辑 ===
            document.body.classList.remove('cinema-vertical-mode');
            if (isCinemaModeEnabled) {
                if (!document.body.classList.contains('cinema-mode-active')) {
                    document.body.classList.add('cinema-mode-active');
                    fitVideoToWindow();
                }
                if (!document.body.classList.contains('cinema-playing') && !document.body.classList.contains('cinema-active')) {
                    document.body.classList.add('cinema-playing');
                }
            }
            ensureOverlayButtons();
            ensureTheaterMode();
            setupAutoPlayNext();
            autoDismissContinueWatching();
            lockMaxResolution();
            skipVideoAds();
        } else {
            // 首页 / 列表页
            document.body.classList.remove('cinema-mode-active');
            document.body.classList.remove('cinema-vertical-mode');
            document.body.classList.remove('cinema-playing');
            document.body.classList.remove('cinema-active');
            document.body.classList.remove('hide-cursor');
            document.documentElement.style.removeProperty('overflow');
            document.body.style.removeProperty('overflow');
        }
    }

    // 15. 沉浸式隐显交互控制 (鼠标静止 1.8s 自动淡出所有控件，复刻 FikFap)
    let cinemaTimer = null;
    function handleUserActivity() {
        if (isAutoAdvancing) return;
        document.body.classList.remove('cinema-playing');
        document.body.classList.add('cinema-active');
        document.body.classList.remove('hide-cursor');

        if (cinemaTimer) clearTimeout(cinemaTimer);

        cinemaTimer = setTimeout(() => {
            const isWatchPage = window.location.pathname.includes('/watch');
            const isShorts = window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical';

            if (isWatchPage || isShorts) {
                document.body.classList.remove('cinema-active');
                document.body.classList.add('cinema-playing');
                document.body.classList.add('hide-cursor');
            }
        }, 1800);
    }

    // 初始状态：1.5 秒后自动淡出 UI 进入沉浸播放状态
    setTimeout(() => {
        const isWatchPage = window.location.pathname.includes('/watch');
        const isShorts = window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical';
        if (isWatchPage || isShorts) {
            document.body.classList.remove('cinema-active');
            document.body.classList.add('cinema-playing');
        }
    }, 1500);

    window.addEventListener('mousemove', handleUserActivity, { passive: true });
    window.addEventListener('mousedown', handleUserActivity, { passive: true });
    window.addEventListener('click', handleUserActivity, { passive: true });
    window.addEventListener('mouseleave', () => {
        const isWatchPage = window.location.pathname.includes('/watch');
        const isShorts = window.location.pathname.includes('/shorts') || currentVideoMode === 'vertical';
        if (isWatchPage || isShorts) {
            document.body.classList.remove('cinema-active');
            document.body.classList.add('cinema-playing');
            document.body.classList.add('hide-cursor');
        }
    });

    window.addEventListener('resize', () => {
        if (currentVideoMode === 'vertical') fitVerticalVideo();
        else fitVideoToWindow();
    });

    // 16. 鼠标滚轮/触控板滑动换视频 (横竖屏自动适配)
    let wheelDelta = 0;
    let wheelCooldown = false;

    window.addEventListener('wheel', (e) => {
        handleUserActivity();
        const isWatchOrShorts = window.location.pathname.includes('/watch') || window.location.pathname.includes('/shorts');
        if (!isWatchOrShorts) return;
        if (wheelCooldown) return;

        wheelDelta += e.deltaY;

        if (wheelDelta > 75) {
            wheelCooldown = true;
            wheelDelta = 0;
            playNextVideo();
            setTimeout(() => { wheelCooldown = false; }, 1200);
        } else if (wheelDelta < -75) {
            wheelCooldown = true;
            wheelDelta = 0;
            playPreviousVideo();
            setTimeout(() => { wheelCooldown = false; }, 1200);
        }

        clearTimeout(window._wheelResetTimer);
        window._wheelResetTimer = setTimeout(() => { wheelDelta = 0; }, 300);
    }, { passive: true });

    // 17. 网络状态感知
    window.addEventListener('online', () => {
        showToast('🌐 网络连接已恢复');
        setTimeout(() => { location.reload(); }, 600);
    });

    window.addEventListener('offline', () => {
        showToast('⚠️ 当前网络连接断开，请检查网络或代理');
    });

    // 18. 全局周期性轮询与页面切歌监听 (120ms 高频侦测，确保毫秒级感知切歌)
    setInterval(() => {
        detectVideoOrientation();
        hookVideoEvents();
        checkShortsAutoPlay();
        skipVideoAds();
        lockMaxResolution();
        updateWatchState();
        checkPlaybackHealth();
    }, 120);

    window.addEventListener('yt-navigate-finish', () => {
        lastQualityLockedVideo = '';
        setTimeout(detectVideoOrientation, 150);
        setTimeout(hookVideoEvents, 200);
        setTimeout(() => {
            updateWatchState();
            if (currentVideoMode === 'vertical') fitVerticalVideo();
            else fitVideoToWindow();
        }, 300);
        setTimeout(lockMaxResolution, 600);
        setTimeout(skipVideoAds, 300);
    });

    window.addEventListener('popstate', () => {
        detectVideoOrientation();
        updateWatchState();
    });

    // 19. 全局键盘快捷键控制：向下键/向上键秒切视频、P开启画中画、O切换横竖屏、倍速微调
    window.addEventListener('keydown', (e) => {
        const tag = (e.target && e.target.tagName) ? e.target.tagName.toLowerCase() : '';
        if (tag === 'input' || tag === 'textarea' || (e.target && e.target.isContentEditable)) {
            return;
        }

        handleUserActivity();

        if (e.key === 'ArrowDown' || e.key === 'PageDown') {
            e.preventDefault();
            e.stopPropagation();
            activeVideoId = '';
            hasReachedMidpoint = false;
            hasTriggeredEnd = false;
            showToast('⏭ 下一个视频');
            playNextVideo();
        } else if (e.key === 'ArrowUp' || e.key === 'PageUp') {
            e.preventDefault();
            e.stopPropagation();
            activeVideoId = '';
            hasReachedMidpoint = false;
            hasTriggeredEnd = false;
            showToast('⏮ 上一个视频');
            playPreviousVideo();
        } else if (e.key === 'p' || e.key === 'P') {
            e.preventDefault();
            togglePictureInPicture();
        } else if (e.key === 'o' || e.key === 'O') {
            e.preventDefault();
            const nextMode = (currentVideoMode === 'horizontal') ? 'vertical' : 'horizontal';
            currentVideoMode = nextMode;
            if (nextMode === 'vertical') showToast('📱 切换为 9:16 竖屏模式');
            else showToast('🎬 切换为 16:9 影院模式');
            try {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.youtubeBridge) {
                    window.webkit.messageHandlers.youtubeBridge.postMessage({ action: 'setAspectRatio', mode: nextMode });
                }
            } catch(err) {}
            updateWatchState();
        } else if (e.key === ']' || (e.shiftKey && (e.key === '>' || e.key === '.'))) {
            e.preventDefault();
            adjustPlaybackSpeed(0.25);
        } else if (e.key === '[' || (e.shiftKey && (e.key === '<' || e.key === ','))) {
            e.preventDefault();
            adjustPlaybackSpeed(-0.25);
        } else if (e.key === '0') {
            e.preventDefault();
            resetPlaybackSpeed();
        } else if (e.key === 'Escape') {
            const isWatchOrShorts = window.location.pathname.includes('/watch') || window.location.pathname.includes('/shorts');
            if (isWatchOrShorts) {
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

// 顶部 28px 原生拖拽标题栏：避让左侧交通灯与浮动按钮，中间宽广区域支持拖动与双击全屏
class DraggableTitleBar: NSView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        if point.x < 80 {
            return nil
        }
        if point.x < 180 {
            return nil
        }
        if point.x > (bounds.width - 120) {
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

class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!
    var progressIndicator: NSProgressIndicator!
    var playbackActivity: NSObjectProtocol?
    var displaySleepAssertionID: IOPMAssertionID = 0
    var reconnectTimer: Timer?

    // 智能横竖屏状态记忆与切换
    var currentMode: String = "horizontal"
    var lastHorizontalFrame: NSRect?

    func applicationDidFinishLaunching(_ notification: Notification) {
        var targetURLString = "https://www.youtube.com"
        for arg in CommandLine.arguments.dropFirst() {
            if arg.hasPrefix("http://") || arg.hasPrefix("https://") {
                targetURLString = arg
                break
            }
        }
        guard let url = URL(string: targetURLString) else { return }

        // 彻底防止 macOS 屏幕休眠、系统休眠与 App Nap 断流（确保长视频播放时屏幕永不黑屏）
        playbackActivity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleDisplaySleepDisabled, .idleSystemSleepDisabled, .latencyCritical],
            reason: "YouTube Video Streaming - Prevent Display Sleep"
        )

        IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "YouTube Video Playback Display Sleep Prevention" as CFString,
            &displaySleepAssertionID
        )

        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultWidth: CGFloat = 1280
        let defaultHeight: CGFloat = 720
        let originX = screenFrame.midX - (defaultWidth / 2)
        let originY = screenFrame.midY - (defaultHeight / 2)
        let windowRect = NSRect(x: originX, y: originY, width: defaultWidth, height: defaultHeight)
        lastHorizontalFrame = windowRect

        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.delegate = self
        window.minSize = NSSize(width: 640, height: 360)
        window.aspectRatio = NSSize(width: 16, height: 9)
        window.collectionBehavior = [.fullScreenPrimary, .fullScreenAllowsTiling]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.black
        window.setFrameAutosaveName("YouTubeMainWindow")

        // WebKit 配置与 JS 原生通信 Bridge
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()

        let userContentController = WKUserContentController()
        userContentController.add(self, name: "youtubeBridge")
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
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")

        webView = WKWebView(frame: windowRect, configuration: configuration)
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"

        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = NSColor.black
        }
        webView.setValue(false, forKey: "drawsBackground")

        // 顶部 2px 极简加载条
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

    // MARK: - WKScriptMessageHandler: 自动响应横屏(16:9)与竖屏(9:16 FikFap模式)切换与原生切歌按键

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "youtubeBridge",
              let dict = message.body as? [String: Any],
              let action = dict["action"] as? String else { return }

        if action == "log", let text = dict["text"] as? String {
            let lvl = dict["level"] as? String ?? "INFO"
            let logLine = "[\(lvl)] \(text)\n"
            print(logLine, terminator: "")
            if let data = logLine.data(using: .utf8) {
                let logURL = URL(fileURLWithPath: "/tmp/youtube_debug.log")
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                } else {
                    try? data.write(to: logURL)
                }
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if action == "nextVideo" {
                self.sendSingleNativeDownArrow()
            } else if action == "prevVideo" {
                self.sendSingleNativeUpArrow()
            } else if action == "setAspectRatio", let mode = dict["mode"] as? String {
                self.handleAspectRatioChange(mode: mode)
            }
        }
    }

    // 发送原生硬件级真实 Down Arrow 按键事件 (三路穿透：CGEvent 硬件事件 + NSWindow.sendEvent + WKWebView.keyDown)
    func sendSingleNativeDownArrow() {
        guard let window = self.window, let webView = self.webView else { return }
        window.makeFirstResponder(webView)

        let pid = NSRunningApplication.current.processIdentifier
        if let eventDown = CGEvent(keyboardEventSource: nil, virtualKey: 125, keyDown: true) {
            eventDown.postToPid(pid)
        }
        if let eventUp = CGEvent(keyboardEventSource: nil, virtualKey: 125, keyDown: false) {
            eventUp.postToPid(pid)
        }

        let char = String(utf16CodeUnits: [0xF701], count: 1)
        let uptime = ProcessInfo.processInfo.systemUptime

        if let keyDownEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: uptime,
            windowNumber: window.windowNumber,
            context: nil,
            characters: char,
            charactersIgnoringModifiers: char,
            isARepeat: false,
            keyCode: 125
        ) {
            window.sendEvent(keyDownEvent)
            webView.keyDown(with: keyDownEvent)
        }

        if let keyUpEvent = NSEvent.keyEvent(
            with: .keyUp,
            location: .zero,
            modifierFlags: [],
            timestamp: uptime + 0.05,
            windowNumber: window.windowNumber,
            context: nil,
            characters: char,
            charactersIgnoringModifiers: char,
            isARepeat: false,
            keyCode: 125
        ) {
            window.sendEvent(keyUpEvent)
            webView.keyUp(with: keyUpEvent)
        }
    }

    // 发送原生硬件级真实 Up Arrow 按键事件
    func sendSingleNativeUpArrow() {
        guard let window = self.window, let webView = self.webView else { return }
        window.makeFirstResponder(webView)

        let pid = NSRunningApplication.current.processIdentifier
        if let eventDown = CGEvent(keyboardEventSource: nil, virtualKey: 126, keyDown: true) {
            eventDown.postToPid(pid)
        }
        if let eventUp = CGEvent(keyboardEventSource: nil, virtualKey: 126, keyDown: false) {
            eventUp.postToPid(pid)
        }

        let char = String(utf16CodeUnits: [0xF700], count: 1)
        let uptime = ProcessInfo.processInfo.systemUptime

        if let keyDownEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: uptime,
            windowNumber: window.windowNumber,
            context: nil,
            characters: char,
            charactersIgnoringModifiers: char,
            isARepeat: false,
            keyCode: 126
        ) {
            window.sendEvent(keyDownEvent)
            webView.keyDown(with: keyDownEvent)
        }

        if let keyUpEvent = NSEvent.keyEvent(
            with: .keyUp,
            location: .zero,
            modifierFlags: [],
            timestamp: uptime + 0.05,
            windowNumber: window.windowNumber,
            context: nil,
            characters: char,
            charactersIgnoringModifiers: char,
            isARepeat: false,
            keyCode: 126
        ) {
            window.sendEvent(keyUpEvent)
            webView.keyUp(with: keyUpEvent)
        }
    }

    func handleAspectRatioChange(mode: String) {
        guard mode != currentMode else { return }
        currentMode = mode
        print("[YouTubeApp] Switching window presentation mode to: \(mode)")

        // 若处于 macOS 原生全屏状态，仅更新比例属性，不打扰全屏空间
        if window.styleMask.contains(.fullScreen) {
            if mode == "vertical" {
                window.aspectRatio = NSSize(width: 9, height: 16)
                window.minSize = NSSize(width: 360, height: 640)
            } else {
                window.aspectRatio = NSSize(width: 16, height: 9)
                window.minSize = NSSize(width: 640, height: 360)
            }
            return
        }

        let currentFrame = window.frame
        let midX = currentFrame.midX
        let midY = currentFrame.midY
        let screen = window.screen ?? NSScreen.main ?? NSScreen.screens[0]
        let maxAvailableHeight = screen.visibleFrame.height - 40

        if mode == "vertical" {
            // 保存当前的横屏窗口位置与尺寸
            lastHorizontalFrame = currentFrame

            // 切换为 9:16 FikFap 竖屏比例（窗口平滑缩放，与 FikFap 保持一致）
            let targetHeight = min(820, maxAvailableHeight)
            let targetWidth = round(targetHeight * 9.0 / 16.0)
            let originX = max(screen.visibleFrame.minX + 20, min(screen.visibleFrame.maxX - targetWidth - 20, midX - targetWidth / 2))
            let originY = max(screen.visibleFrame.minY + 20, min(screen.visibleFrame.maxY - targetHeight - 20, midY - targetHeight / 2))
            let newFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)

            window.aspectRatio = NSSize.zero
            window.minSize = NSSize(width: 320, height: 568)
            window.setFrame(newFrame, display: true, animate: true)
            window.aspectRatio = NSSize(width: 9, height: 16)
        } else {
            // 切回 16:9 横屏影院模式
            let targetFrame: NSRect
            if let saved = lastHorizontalFrame {
                targetFrame = saved
            } else {
                let maxW = screen.visibleFrame.width - 60
                let targetWidth: CGFloat = min(1280, maxW)
                let targetHeight: CGFloat = round(targetWidth * 9.0 / 16.0)
                let originX = max(screen.visibleFrame.minX + 20, midX - targetWidth / 2)
                let originY = max(screen.visibleFrame.minY + 20, midY - targetHeight / 2)
                targetFrame = NSRect(x: originX, y: originY, width: targetWidth, height: targetHeight)
            }

            window.aspectRatio = NSSize.zero
            window.minSize = NSSize(width: 480, height: 270)
            window.setFrame(targetFrame, display: true, animate: true)
            window.aspectRatio = NSSize(width: 16, height: 9)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if displaySleepAssertionID != 0 {
            IOPMAssertionRelease(displaySleepAssertionID)
            displaySleepAssertionID = 0
        }
        if let activity = playbackActivity {
            ProcessInfo.processInfo.endActivity(activity)
            playbackActivity = nil
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

        let host = (targetURL.host ?? "").lowercased()

        // 1. 新窗口/无目标弹窗导航处理 (targetFrame == nil)
        if navigationAction.targetFrame == nil {
            // 彻底阻断所有广告追踪雷达 (sodar) 与外部广告联盟尝试新建窗口
            if host.contains("googlesyndication.com") ||
               host.contains("doubleclick.net") ||
               host.contains("googleadservices.com") ||
               urlString.contains("/sodar/") ||
               urlString.contains("/pagead/") {
                print("[YouTubeApp] Silently blocked ad/sodar new window request: \(urlString)")
                decisionHandler(.cancel)
                return
            }

            if host.contains("youtube.com") || host.contains("youtu.be") {
                webView.load(navigationAction.request)
            } else if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(targetURL)
            }
            decisionHandler(.cancel)
            return
        }

        // 2. 主页面 (mainFrame) 导航处理
        if navigationAction.targetFrame?.isMainFrame == true {
            // 彻底防止主页面被广告/sodar 重定向跳转
            if host.contains("googlesyndication.com") ||
               host.contains("doubleclick.net") ||
               host.contains("googleadservices.com") ||
               urlString.contains("/sodar/") ||
               urlString.contains("/pagead/") {
                print("[YouTubeApp] Silently blocked mainFrame ad/sodar navigation: \(urlString)")
                decisionHandler(.cancel)
                return
            }

            if scheme != "http" && scheme != "https" {
                NSWorkspace.shared.open(targetURL)
                decisionHandler(.cancel)
                return
            }

            let isYouTubeDomain = host.contains("youtube.com") || host.contains("youtu.be")
            let isAuthDomain = host.contains("accounts.google.com") ||
                               host.contains("myaccount.google.com") ||
                               host.contains("googleusercontent.com") ||
                               host.contains("gstatic.com") ||
                               host.contains("googleapis.com")

            if isYouTubeDomain || isAuthDomain {
                decisionHandler(.allow)
                return
            }

            // 用户在简介或评论中主动点击的外部链接，唤起默认浏览器打开
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(targetURL)
            }
            decisionHandler(.cancel)
            return
        }

        // 3. 内部嵌入子框架 (subframe / iframe)
        // 仅拦截 sodar 探测，放行 YouTube 播放器及内部组件的子框架加载，确保播放器不发生媒体断流或黑屏
        if urlString.contains("/sodar/") {
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let targetURL = navigationAction.request.url else { return nil }
        let host = (targetURL.host ?? "").lowercased()
        let urlString = targetURL.absoluteString

        // 彻底阻断广告反作弊脚本 (sodar) 尝试创建的新窗口/弹窗
        if host.contains("googlesyndication.com") ||
           host.contains("doubleclick.net") ||
           host.contains("googleadservices.com") ||
           urlString.contains("/sodar/") ||
           urlString.contains("/pagead/") {
            print("[YouTubeApp] Silently blocked ad/sodar popup request: \(urlString)")
            return nil
        }

        if navigationAction.targetFrame == nil {
            if (host.contains("youtube.com") || host.contains("youtu.be")) && urlString != "about:blank" {
                webView.load(navigationAction.request)
            } else if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(targetURL)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        reconnectTimer?.invalidate()
        reconnectTimer = nil

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
        if nsError.code == NSURLErrorCancelled || nsError.code == 102 || nsError.code >= 0 {
            return
        }
        print("[YouTubeApp] Network error: \(error.localizedDescription) (code: \(nsError.code))")
        handleNetworkError(error: nsError)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled || nsError.code == 102 || nsError.code >= 0 {
            return
        }
        print("[YouTubeApp] Navigation error: \(error.localizedDescription)")
    }

    func handleNetworkError(error: NSError) {
        let errorHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    margin: 0; padding: 0;
                    display: flex; flex-direction: column;
                    align-items: center; justify-content: center;
                    height: 100vh; background-color: #050507;
                    color: #ffffff; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, sans-serif;
                    user-select: none; -webkit-user-select: none;
                }
                .icon { font-size: 52px; margin-bottom: 20px; animation: pulse 2s infinite ease-in-out; }
                h2 { font-size: 20px; font-weight: 600; margin: 0 0 10px 0; letter-spacing: -0.3px; }
                p { font-size: 14px; color: rgba(255,255,255,0.6); max-width: 420px; text-align: center; line-height: 1.5; margin: 0 0 24px 0; }
                .retry-btn {
                    padding: 10px 24px; border-radius: 20px;
                    background: rgba(255,255,255,0.12);
                    border: 1px solid rgba(255,255,255,0.25);
                    color: #ffffff; font-size: 14px; font-weight: 600;
                    cursor: pointer; transition: all 0.2s ease;
                }
                .retry-btn:hover { background: rgba(255,255,255,0.22); transform: scale(1.04); }
                .hint { font-size: 12px; color: rgba(255,255,255,0.35); margin-top: 16px; }
                @keyframes pulse { 0% { opacity: 0.6; transform: scale(0.98); } 50% { opacity: 1; transform: scale(1.02); } 100% { opacity: 0.6; transform: scale(0.98); } }
            </style>
        </head>
        <body>
            <div class="icon">🌐</div>
            <h2>网络连接正在建立中</h2>
            <p>正在连接 YouTube 服务器。若您启用了代理软件（如 Clash、Shadowrocket 等），请确认系统代理已开启并选择有效节点。</p>
            <button class="retry-btn" onclick="window.location.href='https://www.youtube.com'">🔄 立即重连</button>
            <div class="hint">客户端每隔 4 秒会自动尝试自愈重连...</div>
        </body>
        </html>
        """
        webView.loadHTMLString(errorHTML, baseURL: URL(string: "https://www.youtube.com"))

        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            print("[YouTubeApp] Auto reconnect check...")
            if let url = URL(string: "https://www.youtube.com") {
                self.webView.load(URLRequest(url: url))
            }
        }
    }

    // MARK: - 原生菜单

    func setupMainMenu() {
        let mainMenu = NSMenu()

        // 1. App Menu
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

        // 2. Edit Menu (支持搜索框剪切板与 Cmd+V 粘贴)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 3. Control Menu (下一部/上一部视频快捷控制，复刻 FikFap)
        let controlMenuItem = NSMenuItem()
        let controlMenu = NSMenu(title: "Control")
        let nextVideoItem = NSMenuItem(title: "Next Video", action: #selector(triggerNextVideo), keyEquivalent: "\u{F701}")
        nextVideoItem.target = self
        controlMenu.addItem(nextVideoItem)

        let prevVideoItem = NSMenuItem(title: "Previous Video", action: #selector(triggerPrevVideo), keyEquivalent: "\u{F700}")
        prevVideoItem.target = self
        controlMenu.addItem(prevVideoItem)
        controlMenuItem.submenu = controlMenu
        mainMenu.addItem(controlMenuItem)

        // 4. View Menu
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")
        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        fullScreenItem.target = self
        viewMenu.addItem(fullScreenItem)

        let toggleOrientationItem = NSMenuItem(title: "Toggle 16:9 / 9:16 Mode", action: #selector(toggleOrientation), keyEquivalent: "o")
        toggleOrientationItem.keyEquivalentModifierMask = [.command]
        toggleOrientationItem.target = self
        viewMenu.addItem(toggleOrientationItem)
        viewMenu.addItem(NSMenuItem.separator())

        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)

        let forceReloadItem = NSMenuItem(title: "Force Reload (Clear Cache)", action: #selector(forceReload), keyEquivalent: "R")
        forceReloadItem.keyEquivalentModifierMask = [.command, .shift]
        forceReloadItem.target = self
        viewMenu.addItem(forceReloadItem)
        viewMenu.addItem(NSMenuItem.separator())

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

        // 4. History Menu
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

        // 5. Window Menu
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

    @objc func triggerNextVideo() {
        sendSingleNativeDownArrow()
        webView.evaluateJavaScript("playNextVideo();", completionHandler: nil)
    }

    @objc func triggerPrevVideo() {
        sendSingleNativeUpArrow()
        webView.evaluateJavaScript("playPreviousVideo();", completionHandler: nil)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let first = urls.first {
            webView?.load(URLRequest(url: first))
        }
    }

    @objc func toggleOrientation() {
        let newMode = (currentMode == "horizontal") ? "vertical" : "horizontal"
        handleAspectRatioChange(mode: newMode)
        let toastText = (newMode == "vertical") ? "📱 切换为 9:16 竖屏模式" : "🎬 切换为 16:9 影院模式"
        let js = """
        currentVideoMode = '\(newMode)';
        if (typeof showToast === 'function') showToast('\(toastText)');
        if (typeof updateWatchState === 'function') updateWatchState();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    @objc func goHome() {
        if let url = URL(string: "https://www.youtube.com") {
            webView.load(URLRequest(url: url))
        }
    }
    @objc func reloadPage() { webView.reload() }

    @objc func forceReload() {
        let types = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        WKWebsiteDataStore.default().removeData(ofTypes: Set(types), modifiedSince: Date(timeIntervalSince1970: 0)) { [weak self] in
            self?.webView.reloadFromOrigin()
        }
    }

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
