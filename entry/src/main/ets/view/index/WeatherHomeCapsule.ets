/**
 * @file WeatherHomeCapsule.ets
 * @brief 首页天气胶囊 + 详情半模态
 * @description 置于「必玩推荐」右侧；分割线区隔区块；刷新在气温旁，避免贴近关闭键
 */
import { WeatherService } from '../../service/WeatherService';
import { WeatherSnapshot } from '../../model/WeatherModel';

@Component
export struct WeatherHomeCapsule {
  @State weather: WeatherSnapshot | null = null;
  @State showWeatherSheet: boolean = false;
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    this.loadWeather();
    this.refreshTimer = setInterval(() => this.loadWeather(), 10 * 60 * 1000);
  }

  aboutToDisappear(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  loadWeather(force: boolean = false): void {
    const p = force
      ? WeatherService.getInstance().forceRefresh()
      : WeatherService.getInstance().getCurrentWeather();
    p.then((w: WeatherSnapshot) => {
      this.weather = w;
    }).catch(() => {
    });
  }

  private weatherEmoji(w?: string): string {
    if (!w || w.length === 0) {
      return '⛅';
    }
    if (w.indexOf('雨') >= 0) {
      return '🌧️';
    }
    if (w.indexOf('雪') >= 0) {
      return '❄️';
    }
    if (w.indexOf('云') >= 0 || w.indexOf('阴') >= 0) {
      return '☁️';
    }
    if (w.indexOf('晴') >= 0) {
      return '☀️';
    }
    return '⛅';
  }

  private shortCity(city: string): string {
    return city.replace(/省|市/g, '');
  }

  @Builder
  WeatherDetailSheet(): void {
    Column({ space: 0 }) {
      Text('今日天气')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Divider().color('#E8E8E8').margin({ top: 14, bottom: 18 })

      if (this.weather === null) {
        Text('加载中…').fontSize(14).fontColor($r('app.color.text_tertiary'))
      } else {
        Row({ space: 14 }) {
          Text(this.weatherEmoji(this.weather.weather))
            .fontSize(44)
          Column({ space: 8 }) {
            Row({ space: 10 }) {
              Text(`${this.weather.temperature}°`)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
              Text(this.weather.weather)
                .fontSize(17)
                .fontColor($r('app.color.text_secondary'))
                .alignSelf(ItemAlign.End)
                .margin({ bottom: 6 })
              if (!this.weather.isMock) {
                Text('点击刷新')
                  .fontSize(13)
                  .fontColor($r('app.color.accent'))
                  .alignSelf(ItemAlign.End)
                  .margin({ bottom: 6, left: 4 })
                  .onClick(() => this.loadWeather(true))
              }
            }
            .alignItems(VerticalAlign.Bottom)

            Text(`${this.weather.province} ${this.weather.city}`)
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        Divider().color('#E8E8E8').margin({ top: 20, bottom: 16 })

        Row() {
          this.detailItem(`湿度`, `${this.weather.humidity}${this.weather.humidity.includes('%') ? '' : '%'}`)
          this.detailItem('风向', `${this.weather.windDirection}风 ${this.weather.windPower}`)
        }
        .width('100%')

        if (this.weather.reportTime.length > 0) {
          Divider().color('#E8E8E8').margin({ top: 18, bottom: 12 })
          Text(`更新时间 ${this.weather.reportTime}`)
            .fontSize(11)
            .fontColor('#999')
            .width('100%')
        }

        if (this.weather.fallbackTip !== undefined && this.weather.fallbackTip.length > 0) {
          Divider().color('#E8E8E8').margin({ top: 16, bottom: 12 })
          Text(this.weather.fallbackTip)
            .fontSize(12)
            .fontColor('#B8860B')
            .width('100%')
            .padding(10)
            .backgroundColor('#FFF8E6')
            .borderRadius(8)
        }

        Divider().color('#E8E8E8').margin({ top: 16, bottom: 12 })

        Text(this.weather.hint)
          .fontSize(13)
          .fontColor($r('app.color.accent'))
          .width('100%')
          .padding(12)
          .backgroundColor('#F0F7FF')
          .borderRadius(10)

        if (this.weather.isMock) {
          Text('当前为演示或降级数据，请检查网络与配置')
            .fontSize(11)
            .fontColor('#999')
            .width('100%')
            .margin({ top: 12 })
        }
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 28, bottom: 28 })
    .alignItems(HorizontalAlign.Start)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder
  detailItem(label: string, value: string): void {
    Column({ space: 2 }) {
      Text(value).fontSize(15).fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      Text(label).fontSize(12).fontColor($r('app.color.text_tertiary'))
    }
    .layoutWeight(1)
  }

  build() {
    Row({ space: 4 }) {
      Text(this.weatherEmoji(this.weather?.weather)).fontSize(14)
      Text(`${this.weather?.temperature ?? '--'}°`)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
      Text('|')
        .fontSize(12)
        .fontColor('#99BFFF')
      Text(this.weather ? this.shortCity(this.weather.city) : '--')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: 50 })
    }
    .height(32)
    .padding({ left: 10, right: 10 })
    .backgroundColor('#E8F4FF')
    .borderRadius(16)
    .border({ width: 1, color: 'rgba(0,125,255,0.15)' })
    .onClick(() => {
      this.showWeatherSheet = true;
      this.loadWeather(true);
    })
    .bindSheet($$this.showWeatherSheet, this.WeatherDetailSheet(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      showClose: true,
      onDisappear: (): void => {
        this.showWeatherSheet = false;
      }
    })
  }
}
