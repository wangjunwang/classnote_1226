// entry/src/main/ets/utils/NotificationHelper.ets
import { reminderAgentManager } from '@kit.BackgroundTasksKit';

// 接口定义
interface ReminderWithId {
  reminderId: number;
}

export class NotificationHelper {

  /**
   * 1. 待办进度汇报 (保持不变)
   */
  static async updateDailySummary(finishedCount: number, totalCount: number) {
    const targetHour = 23;
    const targetMinute = 0;
    const titleBase = '今日待办总结';

    const now = new Date();
    if (now.getHours() >= targetHour && now.getMinutes() > 0) { return; }

    try {
      const activeReminders = await reminderAgentManager.getValidReminders();
      for (const r of activeReminders) {
        if (r.title && r.title.includes(titleBase)) {
          const target = r as Object as ReminderWithId;
          const oldId = target.reminderId;
          if (oldId !== undefined && oldId !== null) {
            await reminderAgentManager.cancelReminder(oldId);
          }
        }
      }

      let percent = 0;
      let progressBar = '';
      if (totalCount > 0) {
        percent = Math.round((finishedCount / totalCount) * 100);
        const totalBlocks = 10;
        const filled = Math.round((finishedCount / totalCount) * totalBlocks);
        const empty = totalBlocks - filled;
        progressBar = '━'.repeat(filled) + '─'.repeat(empty);
      } else {
        progressBar = '──────────';
      }

      const reminder: reminderAgentManager.ReminderRequestAlarm = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
        hour: targetHour,
        minute: targetMinute,
        daysOfWeek: [],
        title: `${titleBase} (${percent}%)`,
        content: `${progressBar}\n已完成 ${finishedCount}/${totalCount} 个任务`,
        ringDuration: 0,
        snoozeTimes: 0,
        timeInterval: 0,
        actionButton: [
          { title: '查看', type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE }
        ]
      };
      await reminderAgentManager.publishReminder(reminder);
    } catch (err) {
      console.error('发布待办提醒失败:', JSON.stringify(err));
    }
  }

  /**
   * 2. 课程提醒 (日历提醒)
   * 修改后效果：
   * 标题：上课提醒
   * 内容：
   * 上课时间：10:00
   * 上课班级：全员
   */
  static async addCourseReminder(courseName: string, startTime: number): Promise<number> {
    const courseDate = new Date(startTime);
    // 提醒时间：前一天晚上 22:00
    const remindTime = new Date(startTime);
    remindTime.setDate(remindTime.getDate() - 1);
    remindTime.setHours(22, 0, 0, 0);

    // 如果当前已经过了提醒时间，则不设置
    if (remindTime.getTime() < Date.now()) {
      return -1;
    }

    // 格式化时间 (例如 "10:00")
    const timeStr = `${courseDate.getHours().toString().padStart(2, '0')}:${courseDate.getMinutes().toString().padStart(2, '0')}`;

    const reminder: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: remindTime.getFullYear(),
        month: remindTime.getMonth() + 1,
        day: remindTime.getDate(),
        hour: remindTime.getHours(),
        minute: remindTime.getMinutes(),
      },
      repeatMonths: [],
      repeatDays: [],

      title: '上课提醒',

      // 👇👇👇 【核心修改】 👇👇👇
      // 使用 \n 换行，信息更清晰
      content: `上课时间：${timeStr}\n上课班级：${courseName}`,
      // 👆👆👆

      ringDuration: 0,
      snoozeTimes: 0,
      timeInterval: 0,
      actionButton: [
        { title: '知道了', type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE }
      ]
    };

    try {
      const id = await reminderAgentManager.publishReminder(reminder);
      console.info(`课程前夜提醒设置成功: ID ${id}`);
      return id;
    } catch (err) {
      console.error('设置课程提醒失败:', JSON.stringify(err));
      return -1;
    }
  }

  static async cancelReminder(reminderId: number) {
    if (reminderId < 0) return;
    try {
      await reminderAgentManager.cancelReminder(reminderId);
    } catch (err) {
      console.error('取消提醒失败:', JSON.stringify(err));
    }
  }
}
