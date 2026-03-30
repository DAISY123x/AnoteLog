import router from '@ohos.router';
import { PlaceService } from '../service/PlaceService';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct AddPlacePage {
  @State name: string = '';
  @State address: string = '';
  @State latitude: string = '';
  @State longitude: string = '';
  @State type: string = '景点';
  @State contact: string = '';
  @State isSubmitting: boolean = false;
  @State editId: number = -1;

  private typeOptions: SelectOption[] = [
    { value: '景点' },
    { value: '美食' },
    { value: '酒店' },
    { value: '交通' },
    { value: '购物' },
    { value: '其他' }
  ];

  async onPageShow() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['id']) {
      this.editId = params['id'] as number;
      await this.loadPlaceData(this.editId);
    }
  }

  async loadPlaceData(id: number) {
    try {
      const place = await PlaceService.getInstance().getPlaceById(id);
      if (place) {
        this.name = place.name;
        this.address = place.address;
        this.latitude = place.latitude.toString();
        this.longitude = place.longitude.toString();
        this.type = place.type;
        this.contact = place.contact;
      }
    } catch (e) {
      console.error('Load place failed', e);
      promptAction.showToast({ message: '加载数据失败' });
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.ic_arrow_back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())
        Text('添加新地点')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding(16)
      .height(56)
      .backgroundColor(Color.White)

      Scroll() {
        Column({ space: 20 }) {
          // Name
          Column() {
            Text('名称 *').fontSize(14).fontColor('#666666').margin({bottom: 8})
            TextInput({ text: this.name, placeholder: '请输入地点名称' })
              .height(48)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .onChange((val) => this.name = val)
          }.alignItems(HorizontalAlign.Start).width('100%')

          // Address
          Column() {
            Text('详细地址 *').fontSize(14).fontColor('#666666').margin({bottom: 8})
            TextInput({ text: this.address, placeholder: '请输入详细地址' })
              .height(48)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .onChange((val) => this.address = val)
          }.alignItems(HorizontalAlign.Start).width('100%')

          // Coordinates
          Row({ space: 16 }) {
             Column() {
               Text('纬度 (Latitude) *').fontSize(14).fontColor('#666666').margin({bottom: 8})
               TextInput({ text: this.latitude, placeholder: '如 39.9' })
                 .height(48)
                 .backgroundColor(Color.White)
                 .borderRadius(8)
                 .type(InputType.Number) // Note: InputType.Number might restrict negative/decimal on some devices, be careful. Using Normal for now to be safe with negatives
                 .onChange((val) => this.latitude = val)
                 .width('100%')
             }.layoutWeight(1).alignItems(HorizontalAlign.Start)

             Column() {
               Text('经度 (Longitude) *').fontSize(14).fontColor('#666666').margin({bottom: 8})
               TextInput({ text: this.longitude, placeholder: '如 116.4' })
                 .height(48)
                 .backgroundColor(Color.White)
                 .borderRadius(8)
                 .type(InputType.Number)
                 .onChange((val) => this.longitude = val)
                 .width('100%')
             }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }.width('100%')

          // Type
          Column() {
             Text('地点类型').fontSize(14).fontColor('#666666').margin({bottom: 8})
             Select(this.typeOptions)
               .selected(0)
               .value(this.type)
               .font({ size: 16 })
               .selectedOptionFont({ size: 16 })
               .optionFont({ size: 16 })
               .onSelect((index, value) => {
                 this.type = value;
               })
               .width('100%')
               .height(48)
               .borderRadius(8)
               .backgroundColor(Color.White)
          }.alignItems(HorizontalAlign.Start).width('100%')

          // Contact
          Column() {
            Text('联系方式').fontSize(14).fontColor('#666666').margin({bottom: 8})
            TextInput({ text: this.contact, placeholder: '电话或邮箱 (选填)' })
              .height(48)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .onChange((val) => this.contact = val)
          }.alignItems(HorizontalAlign.Start).width('100%')

          // Buttons
          Row({ space: 16 }) {
            Button('重置')
              .backgroundColor('#E0E0E0')
              .fontColor(Color.Black)
              .layoutWeight(1)
              .height(48)
              .onClick(() => this.resetForm())
            
            Button(this.isSubmitting ? '提交中...' : '提交')
              .layoutWeight(1)
              .height(48)
              .enabled(!this.isSubmitting)
              .onClick(() => this.submitForm())
          }
          .margin({ top: 20 })
        }
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  resetForm() {
    this.name = '';
    this.address = '';
    this.latitude = '';
    this.longitude = '';
    this.type = '景点';
    this.contact = '';
  }

  async submitForm() {
    if (this.isSubmitting) return;
    this.isSubmitting = true;

    try {
      const lat = parseFloat(this.latitude);
      const lng = parseFloat(this.longitude);

      if (isNaN(lat) || isNaN(lng)) {
        promptAction.showToast({ message: '请输入有效的经纬度数值' });
        this.isSubmitting = false;
        return;
      }

      if (this.editId > 0) {
        await PlaceService.getInstance().updatePlace({
          id: this.editId,
          name: this.name,
          address: this.address,
          latitude: lat,
          longitude: lng,
          type: this.type,
          contact: this.contact,
          createTime: 0, // Not used in update
          updateTime: Date.now()
        });
        promptAction.showToast({ message: '更新成功' });
      } else {
        await PlaceService.getInstance().addPlace({
          name: this.name,
          address: this.address,
          latitude: lat,
          longitude: lng,
          type: this.type,
          contact: this.contact,
          createTime: Date.now(),
          updateTime: Date.now()
        });
        promptAction.showToast({ message: '添加成功' });
      }

      setTimeout(() => {
        router.back();
      }, 500);

    } catch (err) {
      const e = err as Error;
      promptAction.showToast({ message: e.message || '提交失败' });
    } finally {
      this.isSubmitting = false;
    }
  }
}
