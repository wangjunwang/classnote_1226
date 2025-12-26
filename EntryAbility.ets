import { AbilityConstant, UIAbility, Want, ConfigurationConstant, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {

  private handleShortcut(want: Want) {
    if (want.parameters && want.parameters['shortcutAction']) {
      const action = want.parameters['shortcutAction'] as string;
      AppStorage.setOrCreate('GlobalShortcutAction', action);
    }
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. 设置颜色模式跟随系统
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    // 2. 初始化深色模式状态
    const colorMode = this.context.config.colorMode;
    AppStorage.setOrCreate('isDarkMode', colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);

    // 3. 【新增】初始化主题风格 (默认橙色)
    // 如果您有持久化存储 (Preferences)，这里应该先从本地读取，这里暂用内存默认值
    AppStorage.setOrCreate('GlobalThemeStyle', 'orange');

    // 4. 处理快捷方式
    this.handleShortcut(want);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    // 4. 【核心】监听系统深色模式切换，实时更新全局变量
    const colorMode = newConfig.colorMode;
    if (colorMode !== undefined) {
      AppStorage.setOrCreate('isDarkMode', colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 5. 【关键修复】加载页面路径
    // 如果您的文件名是 CalendarPage.ets，请改为 'pages/CalendarPage'
    // 如果您的文件名是 Index.ets (默认)，请保持 'pages/Index'
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
    });

    notificationManager.requestEnableNotification();
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleShortcut(want);
  }
}
