// entry/src/main/ets/pages/StatisticsPage.ets
import { dbHelper, GroupStat, CreditStats } from '../db/DBHelper';

@Component
struct DataCard {
  title: string = '';
  value: string = '';
  subText: string = '';
  // 默认图标
  icon: Resource = $r('sys.symbol.circle');
  color1: string = '#007DFF';
  color2: string = '#0055FF';

  build() {
    Column() {
      Row() {
        Text(this.title).fontSize(14).fontColor('rgba(255,255,255,0.9)')
        Blank()
        SymbolGlyph(this.icon).fontSize(20).fontColor([Color.White])
      }.width('100%').margin({ bottom: 10 })

      Text(this.value).fontSize(28).fontWeight(FontWeight.Bold).fontColor(Color.White)
      Text(this.subText).fontSize(12).fontColor('rgba(255,255,255,0.7)').margin({ top: 4 })
    }
    .width('100%')
    .height(110)
    .padding(15)
    .linearGradient({ angle: 135, colors: [[this.color1, 0.0], [this.color2, 1.0]] })
    .borderRadius(20)
    .shadow({ radius: 10, color: this.color2 + '40', offsetY: 5 })
    .alignItems(HorizontalAlign.Start)
    .stateStyles({
      pressed: { .scale({ x: 0.96, y: 0.96 }) },
      normal: { .scale({ x: 1.0, y: 1.0 }) }
    })
    .animation({ duration: 200 })
  }
}

@Entry
@Component
export struct StatisticsPage {
  @State weekFinished: number = 0
  @State monthFinished: number = 0
  @State studentCount: number = 0
  @State creditStats: CreditStats = { used: 0, total: 0 }
  @State knowledgeStats: GroupStat[] = []
  @StorageProp('AppGlobalUpdate') @Watch('loadData') updateSignal: number = 0;

  async aboutToAppear() {
    await this.loadData();
  }

  async loadData() {
    const pStats = await dbHelper.getPeriodStats();
    this.weekFinished = pStats.week;
    this.monthFinished = pStats.month;
    this.creditStats = await dbHelper.getTotalCreditStats();
    this.knowledgeStats = await dbHelper.getKnowledgeStats();
    const students = await dbHelper.getStudents();
    this.studentCount = students.length;
  }

  build() {
    Column() {
      // 标题
      Text("数据统计")
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ top: 50, left: 20, bottom: 15 })
        .backgroundColor('#F2F3F5')

      Scroll() {
        Column({ space: 15 }) {
          // 1. 顶部数据卡片 (Grid 布局)
          Grid() {
            GridItem() {
              DataCard({
                title: '本周消课', value: this.weekFinished.toString(), subText: '节课程',
                icon: $r('sys.symbol.calendar'), color1: '#007DFF', color2: '#0055FF'
              })
            }
            GridItem() {
              DataCard({
                title: '本月消课', value: this.monthFinished.toString(), subText: '节课程',
                // 【修复】waveform_path -> text_aligncenter (形状类似统计图)
                icon: $r('sys.symbol.text_aligncenter'), color1: '#FF9900', color2: '#FF7700'
              })
            }
            GridItem() {
              DataCard({
                title: '总学员', value: this.studentCount.toString(), subText: '人',
                icon: $r('sys.symbol.person_2_fill'), color1: '#00CC88', color2: '#00AA66'
              })
            }
            GridItem() {
              DataCard({
                title: '剩余总课时', value: (this.creditStats.total - this.creditStats.used).toString(), subText: '课时',
                icon: $r('sys.symbol.clock_fill'), color1: '#9900FF', color2: '#7700DD'
              })
            }
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .height(230)

          // 2. 知识点排行榜
          Column() {
            Row() {
              // 热门排行图标
              SymbolGlyph($r('sys.symbol.star_fill')).fontSize(20).fontColor(['#FFD700']).margin({ right: 8 })
              Text('热门知识点 TOP 5').fontSize(16).fontWeight(FontWeight.Bold)
            }.width('100%').margin({ bottom: 15 })

            if (this.knowledgeStats.length === 0) {
              Text('暂无数据').fontColor('#CCC').fontSize(14).height(100)
            } else {
              List({ space: 15 }) {
                ForEach(this.knowledgeStats, (item: GroupStat, index: number) => {
                  ListItem() {
                    Row() {
                      // 排名标号
                      Text((index + 1).toString())
                        .fontSize(14).fontWeight(FontWeight.Bold)
                        .fontColor(index < 3 ? '#007DFF' : '#999')
                        .width(24)

                      Column() {
                        Text(item.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#333')
                        // 进度条背景
                        Stack({ alignContent: Alignment.Start }) {
                          Row().width('100%').height(6).backgroundColor('#F0F0F0').borderRadius(3)
                          Row()
                            .width(`${Math.min((item.count / (this.studentCount || 1)) * 100, 100)}%`)
                            .height(6)
                            .backgroundColor(index === 0 ? '#FF9900' : '#007DFF')
                            .borderRadius(3)
                            .animation({ duration: 500, curve: Curve.EaseOut }) // 进度条动画
                        }.width('100%').margin({ top: 6 })
                      }.layoutWeight(1)

                      Text(`${item.count}人`).fontSize(12).fontColor('#666').margin({ left: 10 })
                    }.width('100%')
                  }
                })
              }
            }
          }
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 10, color: '#0F000000', offsetY: 2 })
        }
        .padding({ left: 15, right: 15, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F3F5')
  }
}
