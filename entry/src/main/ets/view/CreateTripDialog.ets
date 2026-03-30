import { promptAction } from '@kit.ArkUI';

interface TextPickerChildItem {
  text: string;
}

interface TextPickerCascadeRangeContent {
  text: string;
  children: Array<TextPickerChildItem>;
}

@CustomDialog
export struct CreateTripDialog {
  controller: CustomDialogController;
  confirm: (name: string, location: string) => void = (name, location) => {
  };
  cancel: () => void = () => {
  };
  // Initial data for editing
  @State tripName: string = '';
  @State selectedLocation: string = '';
  @State private provinceIndex: number = 0;
  @State private cityIndex: number = 0;
  // Mock Data for Cascade Picker
  private locationData: TextPickerCascadeRangeContent[] = [
    {
      text: '北京',
      children: [
        { text: '东城区' } as TextPickerChildItem, { text: '西城区' } as TextPickerChildItem,
        { text: '朝阳区' } as TextPickerChildItem, { text: '海淀区' } as TextPickerChildItem,
        { text: '丰台区' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent,
    {
      text: '上海',
      children: [
        { text: '黄浦区' } as TextPickerChildItem, { text: '徐汇区' } as TextPickerChildItem,
        { text: '长宁区' } as TextPickerChildItem, { text: '静安区' } as TextPickerChildItem,
        { text: '浦东新区' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent,
    {
      text: '广东',
      children: [
        { text: '广州' } as TextPickerChildItem, { text: '深圳' } as TextPickerChildItem,
        { text: '珠海' } as TextPickerChildItem, { text: '汕头' } as TextPickerChildItem,
        { text: '佛山' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent,
    {
      text: '浙江',
      children: [
        { text: '杭州' } as TextPickerChildItem, { text: '宁波' } as TextPickerChildItem,
        { text: '温州' } as TextPickerChildItem, { text: '嘉兴' } as TextPickerChildItem,
        { text: '湖州' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent,
    {
      text: '江苏',
      children: [
        { text: '南京' } as TextPickerChildItem, { text: '苏州' } as TextPickerChildItem,
        { text: '无锡' } as TextPickerChildItem, { text: '常州' } as TextPickerChildItem,
        { text: '南通' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent,
    {
      text: '四川',
      children: [
        { text: '成都' } as TextPickerChildItem, { text: '绵阳' } as TextPickerChildItem,
        { text: '自贡' } as TextPickerChildItem, { text: '攀枝花' } as TextPickerChildItem,
        { text: '泸州' } as TextPickerChildItem
      ]
    } as TextPickerCascadeRangeContent
  ];

  aboutToAppear() {
    // Initialize selection based on passed location string if needed
    // Simple logic to parse "Province City" or just default
    if (this.selectedLocation) {
      // Try to find indices (simplified)
    } else {
      this.updateSelectedLocationString();
    }
  }

  private updateSelectedLocationString() {
    const p = this.locationData[this.provinceIndex];
    if (p && p.children && p.children[this.cityIndex]) {
      this.selectedLocation = `${p.text} ${p.children[this.cityIndex].text}`;
    }
  }

  build() {
    Column() {
      Text(this.tripName ? '编辑行程' : '新建行程')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)

      // 攻略名称输入
      Column() {
        Text('攻略名称')
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 8 })
          .width('100%')

        TextInput({ placeholder: '未命名行程 (默认)', text: this.tripName })
          .maxLength(20)
          .height(48)
          .borderRadius(8)
          .backgroundColor('#F5F5F5')
          .onChange((value) => {
            this.tripName = value;
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 20 })

      // 地区选择
      Column() {
        Text('选择地区')
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 8 })
          .width('100%')

        // Custom Picker Container
        Column() {
          TextPicker({ range: this.locationData, selected: [this.provinceIndex, this.cityIndex] })
            .onChange((value: string | string[], index: number | number[]) => {
              if (Array.isArray(index)) {
                this.provinceIndex = index[0];
                this.cityIndex = index[1];
                this.updateSelectedLocationString();
              }
            })
            .height(120)
            .canLoop(false)
        }
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .padding(4)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .margin({ bottom: 30 })

      // 按钮组
      Row() {
        Button('取消')
          .fontColor('#666')
          .backgroundColor('#F0F0F0')
          .width('40%')
          .height(44)
          .borderRadius(22)
          .onClick(() => {
            this.cancel();
            this.controller.close();
          })

        Button('确认')
          .fontColor(Color.White)
          .backgroundColor($r('app.color.accent'))
          .width('40%')
          .height(44)
          .borderRadius(22)
          .onClick(() => {
            const finalName = this.tripName.trim() || '未命名行程';
            const finalLocation = this.selectedLocation || '北京市';
            this.confirm(finalName, finalLocation);
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 20 })
    }
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .width('100%')
  }
}
