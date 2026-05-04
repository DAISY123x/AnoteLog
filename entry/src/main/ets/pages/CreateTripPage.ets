/**
 * @file CreateTripPage.ets
 * @brief 创建行程中转页
 * @description 从首页点击「新建行程」跳转至此，在 aboutToAppear 中打开 CreateTripDialog，
 * 确认后写入数据库并跳转 NewTripPage，关闭弹窗后自动返回首页。
 * @learning 为什么需要中转页：HarmonyOS @Prop 禁止函数类型，AppStorage 信号法在同页面
 * 内无法通过 onPageShow 触发（中转页进入 → aboutToAppear → 打开弹窗），是最可靠的方案。
 * @see Index, CreateTripDialog, NewTripPage, TripRepository
 */
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';
import { CreateTripDialog } from '../view/CreateTripDialog';
import { TripRepository } from '../repository/TripRepository';
import { Trip } from '../model/TripModel';
import { Logger } from '../utils/Logger';

@Entry
@Component
struct CreateTripPage {
  private tripRepository: TripRepository = new TripRepository();
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CreateTripDialog({
      confirm: (name: string, location: string) => this.saveAndNavigate(name, location)
    }),
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: 0 },
    customStyle: false,
    autoCancel: true
  });

  aboutToAppear(): void {
    // 页面进入后直接打开弹窗
    this.dialogController.open();
  }

  async saveAndNavigate(name: string, location: string): Promise<void> {
    try {
      const trip: Trip = {
        id: null,
        name: name,
        location: location,
        startDate: Date.now(),
        status: 'planning',
        createTime: Date.now(),
        updateTime: Date.now()
      };
      const newTripId = await this.tripRepository.insert(trip);
      trip.id = newTripId;
      promptAction.showToast({ message: '行程创建成功' });
      await router.pushUrl({ url: 'pages/NewTripPage' });
    } catch (e) {
      Logger.error('CreateTripPage', 'Create trip failed', [e]);
      promptAction.showToast({ message: '创建失败' });
    }
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('rgba(0,0,0,0.01)')
  }
}
