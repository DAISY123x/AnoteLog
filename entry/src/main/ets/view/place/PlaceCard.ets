/**
 * @file PlaceCard.ets
 * @brief 景点卡片组件
 * @description 悬浮式景点详情卡片，支持点赞、详情跳转、响应式布局
 * @see PlaceDetailParams, AttractionDetail, LikeRepository, PlaceRepository
 */
import router from '@ohos.router';
import { LikeRepository } from '../../repository/LikeRepository';
import { PlaceRepository } from '../../repository/PlaceRepository';
import { DbPlace } from '../../common/database/RdbManager';
import { promptAction } from '@kit.ArkUI';
import { AIService, AttractionDetail } from '../../service/AIService';
import { Logger } from '../../utils/Logger';
import { PlaceDetailParams } from '../../pages/PlaceDetailPage';

interface CardStyle {
  width: string;
  height: string;
  radius: number;
  bgColor: Color;
}

interface LayoutStyle {
  padding: number;
  textBtnGap: number;
  titleAlign: TextAlign;
}

@Component
export struct PlaceCard {
  @Prop place: PlaceDetailParams;
  @Prop detailInfo: AttractionDetail | null;
  @Prop breakpoint: string;
  @Prop isLoading: boolean;
  @State isHovering: boolean = false;
  @State isLiked: boolean = false;
  @State isButtonLoading: boolean = false;
  private likeRepository: LikeRepository = new LikeRepository();
  private placeRepository: PlaceRepository = new PlaceRepository();

  aboutToAppear() {
    this.checkLikeStatus();
  }

  async checkLikeStatus() {
    try {
      this.isLiked = await this.likeRepository.isLiked(this.place.id, 'place');
    } catch (e) {
      Logger.error('PlaceCard', 'Check like status failed', e);
    }
  }

  /**
   * 切换点赞状态，同时处理地点保存逻辑
   */
  async toggleLike() {
    try {
      let targetId = this.place.id;
      if (!targetId || targetId === 0) {
        const dbPlace: DbPlace = {
          id: 0,
          title: this.place.title,
          type: this.place.type || '景点',
          distanceKm: this.place.distanceKm || 0,
          durationMin: this.place.durationMin || 0,
          note: this.place.note,
          latitude: this.place.latitude,
          longitude: this.place.longitude
        };
        targetId = await this.placeRepository.savePlace(dbPlace);
      }
      if (targetId && targetId > 0) {
        const liked = await this.likeRepository.toggleLike(targetId, 'place');
        this.isLiked = liked;
        promptAction.showToast({ message: liked ? '已添加到我的点赞' : '已取消点赞' });
      }
    } catch (e) {
      Logger.error('PlaceCard', 'Toggle like failed', e);
    }
  }

  // 样式可配置区
  private readonly cardStyle: CardStyle = {
    width: '80%', height: '80%', radius: 16, bgColor: Color.Transparent
  };
  private readonly layoutStyle: LayoutStyle = {
    padding: 24, textBtnGap: 24, titleAlign: TextAlign.Start
  };

  /**
   * 根据断点返回响应式标题字号
   */
  private getTitleSize(): number {
    switch (this.breakpoint) {
      case 'sm': return 24;
      case 'md': return 28;
      case 'lg': return 32;
      default: return 24;
    }
  }

  /**
   * 处理景点详情点击：优先使用已加载数据，否则触发加载后跳转
   */
  async handleInfoClick() {
    if (this.detailInfo) {
      router.pushUrl({ url: 'pages/AttractionInfoPage', params: { detail: this.detailInfo, title: this.place.title } });
      return;
    }
    this.isButtonLoading = true;
    try {
      const details = await AIService.getInstance().getAttractionDetails(this.place.title);
      if (details) {
        router.pushUrl({ url: 'pages/AttractionInfoPage', params: { detail: details, title: this.place.title } });
      } else {
        promptAction.showToast({ message: '获取详情失败，请重试' });
      }
    } catch (e) {
      promptAction.showToast({ message: '网络请求失败' });
    } finally {
      setTimeout(() => { this.isButtonLoading = false; }, 300);
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {
      // 卡片主图
      Image($r('app.media.background11'))
        .width('100%').height('100%').objectFit(ImageFit.Cover)
        .borderRadius(this.cardStyle.radius).clip(true)

      // 渐变遮罩
      Column()
        .width('100%').height('50%')
        .linearGradient({ angle: 180, colors: [['rgba(0,0,0,0)', 0.0], ['rgba(0,0,0,0.8)', 1.0]] })
        .borderRadius({ bottomLeft: this.cardStyle.radius, bottomRight: this.cardStyle.radius })
        .position({ bottom: 0 })

      // 内容区域
      Column({ space: 12 }) {
        Text(this.place.title)
          .fontSize(this.getTitleSize()).fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyOS Sans SC').fontColor(Color.White)
          .textAlign(this.layoutStyle.titleAlign).width('100%')
          .textShadow({ radius: 4, color: 'rgba(0,0,0,0.3)' })

        Text(`——"${this.detailInfo?.description || '这是外地旅客必打卡推荐之一它蕴含着丰富的历史文化底蕴，包括...'}"`)
          .fontSize(16).lineHeight(24).fontColor('rgba(255,255,255,0.95)')
          .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: this.layoutStyle.textBtnGap })

        Row({ space: 12 }) {
          Row() {
            Image($r('app.media.ic_cat_sights')).width(16).height(16).fillColor('rgba(255,255,255,0.9)')
            Text(`${this.place.distanceKm.toFixed(1)}km`).fontSize(14).fontColor('rgba(255,255,255,0.9)')
          }
          Row({ space: 4 }) {
            Text('★').fontSize(16).fontColor('#FFD700')
            Text('4.8').fontSize(14).fontColor('rgba(255,255,255,0.9)')
          }
        }
        .width('100%').justifyContent(FlexAlign.Start).margin({ left: 12 })
      }
      .padding(this.layoutStyle.padding).width('100%').position({ bottom: 0 })

      // 点赞按钮
      Row() {
        Image(this.isLiked ? $r('app.media.ic_home_selected') : $r('app.media.ic_home_normal'))
          .width(28).height(28)
          .fillColor(this.isLiked ? '#FF4D4F' : 'rgba(255,255,255,0.8)')
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.2)' })
      }
      .padding(10).backgroundColor('rgba(0,0,0,0.2)').backdropBlur(10)
      .borderRadius(24).position({ top: 20, right: 20 })
      .onClick(() => this.toggleLike()).zIndex(20)

      // 详情按钮
      Row({ space: 4 }) {
        if (this.isButtonLoading) {
          LoadingProgress().width(16).height(16).color(Color.White)
          Text('加载中...').fontSize(14).fontColor(Color.White)
        } else {
          Text('景点详细信息').fontSize(14).fontColor(Color.White)
          Image($r('app.media.ic_arrow_back')).width(16).height(16)
            .fillColor(Color.White).rotate({ angle: 180 })
        }
      }
      .backgroundColor('rgba(255,255,255,0.2)').backdropBlur(20).borderRadius(20)
      .padding({ left: 16, right: 12, top: 8, bottom: 8 })
      .position({ bottom: this.layoutStyle.padding, right: this.layoutStyle.padding })
      .border({ width: 0.5, color: 'rgba(255,255,255,0.3)' })
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.1)', offsetY: 2 })
      .onClick(() => { if (!this.isButtonLoading) this.handleInfoClick(); })
    }
    .width(this.cardStyle.width).height(this.cardStyle.height)
    .borderRadius(this.cardStyle.radius).backgroundColor(this.cardStyle.bgColor)
    .shadow({ radius: this.isHovering ? 20 : 12, color: 'rgba(0,0,0,0.15)', offsetY: this.isHovering ? 8 : 4 })
    .scale({ x: this.isHovering ? 1.01 : 1.0, y: this.isHovering ? 1.01 : 1.0 })
    .animation({ duration: 300, curve: Curve.EaseOut })
    .onHover((isHover: boolean) => { this.isHovering = isHover; })
  }
}
