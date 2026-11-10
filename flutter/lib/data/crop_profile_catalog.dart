import '../models/crop_profile.dart';

/// Offline crop selection catalog. The wording is orientation only: no
/// agricultural operating thresholds or pump schedules are asserted here.
/// Controller application stays disabled until sources and local calibration
/// have been reviewed and accepted.
class CropProfileCatalog {
  const CropProfileCatalog._();

  static const profiles = <CropProfile>[
    CropProfile(
      id: 'water_spinach',
      nameTh: 'ผักบุ้งจีน',
      nameEn: 'Water spinach',
      group: CropGroup.leafy,
      waterNoteTh: 'ติดตามความชื้นของวัสดุปลูกและตรวจการระบายน้ำก่อนกำหนดรอบให้น้ำ',
      waterNoteEn: 'Monitor growing-media moisture and drainage before setting irrigation.',
      lightNoteTh: 'ตรวจสภาพแสงและอุณหภูมิของจุดปลูกจริง',
      lightNoteEn: 'Check light and temperature at the actual growing location.',
    ),
    CropProfile(
      id: 'lettuce',
      nameTh: 'ผักสลัด / ผักกาดหอม',
      nameEn: 'Lettuce',
      group: CropGroup.leafy,
      waterNoteTh: 'ตรวจความชื้นอย่างสม่ำเสมอ และหลีกเลี่ยงน้ำขังบริเวณราก',
      waterNoteEn: 'Check moisture regularly and avoid waterlogged roots.',
      lightNoteTh: 'สังเกตแสงและความร้อนที่กระทบใบในช่วงกลางวัน',
      lightNoteEn: 'Watch the light and midday heat reaching the leaves.',
    ),
    CropProfile(
      id: 'chinese_kale',
      nameTh: 'คะน้า',
      nameEn: 'Chinese kale',
      group: CropGroup.leafy,
      waterNoteTh: 'ประเมินความชื้นตามชนิดดินและระยะเจริญเติบโต',
      waterNoteEn: 'Assess media moisture for the actual soil and growth stage.',
      lightNoteTh: 'ประเมินสภาพแสงของพื้นที่ก่อนตั้งตารางดูแล',
      lightNoteEn: 'Assess local light before establishing a care schedule.',
    ),
    CropProfile(
      id: 'bok_choy',
      nameTh: 'กวางตุ้ง',
      nameEn: 'Bok choy',
      group: CropGroup.leafy,
      waterNoteTh: 'สำรวจความชื้นและการระบายน้ำในแปลงปลูกก่อนตั้งค่าปั๊ม',
      waterNoteEn: 'Review moisture and drainage before configuring a pump.',
      lightNoteTh: 'ติดตามการเปลี่ยนแปลงของแสงและความร้อนรายวัน',
      lightNoteEn: 'Monitor daily changes in light and heat.',
    ),
    CropProfile(
      id: 'chili',
      nameTh: 'พริก',
      nameEn: 'Chili pepper',
      group: CropGroup.fruiting,
      waterNoteTh: 'ปรับการให้น้ำตามวัสดุปลูกและระยะออกดอกติดผล โดยไม่ใช้ค่าคงที่จากอินเทอร์เน็ต',
      waterNoteEn: 'Adjust irrigation for the media and fruiting stage, not generic web percentages.',
      lightNoteTh: 'ประเมินแสงและอุณหภูมิจริงก่อนเลือกเงื่อนไขควบคุม',
      lightNoteEn: 'Measure local light and temperature before configuring conditions.',
    ),
    CropProfile(
      id: 'tomato',
      nameTh: 'มะเขือเทศ',
      nameEn: 'Tomato',
      group: CropGroup.fruiting,
      waterNoteTh: 'ติดตามความสม่ำเสมอของความชื้นบริเวณราก และตรวจการระบายน้ำ',
      waterNoteEn: 'Monitor root-zone moisture consistency and drainage.',
      lightNoteTh: 'ตรวจแสง อุณหภูมิ และการระบายอากาศของพื้นที่ปลูก',
      lightNoteEn: 'Check light, temperature and ventilation in the growing area.',
    ),
    CropProfile(
      id: 'holy_basil',
      nameTh: 'กะเพรา',
      nameEn: 'Holy basil',
      group: CropGroup.herb,
      waterNoteTh: 'ตรวจการแห้งของผิววัสดุปลูกและสภาพรากก่อนเพิ่มรอบให้น้ำ',
      waterNoteEn: 'Check media surface drying and root conditions before watering.',
      lightNoteTh: 'สังเกตปริมาณแสงในบริเวณที่ปลูกจริง',
      lightNoteEn: 'Observe the light available at the actual location.',
    ),
    CropProfile(
      id: 'thai_basil',
      nameTh: 'โหระพา',
      nameEn: 'Thai basil',
      group: CropGroup.herb,
      waterNoteTh: 'ตั้งรอบให้น้ำหลังสอบเทียบความชื้นของดินหรือวัสดุปลูกจริง',
      waterNoteEn: 'Set irrigation only after calibrating moisture for the actual media.',
      lightNoteTh: 'ติดตามแสงและอุณหภูมิที่จุดติดตั้ง',
      lightNoteEn: 'Monitor light and temperature at the installation site.',
    ),
    CropProfile(
      id: 'cucumber',
      nameTh: 'แตงกวา',
      nameEn: 'Cucumber',
      group: CropGroup.fruiting,
      waterNoteTh: 'ติดตามความชื้นบริเวณรากและการระบายน้ำ โดยพิจารณาระยะติดผล',
      waterNoteEn: 'Monitor root-zone moisture and drainage, considering fruiting stage.',
      lightNoteTh: 'ตรวจแสง อุณหภูมิ และการระบายอากาศรอบต้น',
      lightNoteEn: 'Check light, temperature, and airflow around the plant.',
    ),
    CropProfile(
      id: 'yardlong_bean',
      nameTh: 'ถั่วฝักยาว',
      nameEn: 'Yardlong bean',
      group: CropGroup.fruiting,
      waterNoteTh: 'พิจารณาความชื้นและการระบายน้ำตามระยะเจริญเติบโต',
      waterNoteEn: 'Consider moisture and drainage for the current growth stage.',
      lightNoteTh: 'ตรวจแสงที่ต้นได้รับ และสภาพอากาศภายในพื้นที่ปลูก',
      lightNoteEn: 'Check light exposure and local growing-area conditions.',
    ),
    CropProfile(
      id: 'coriander',
      nameTh: 'ผักชี',
      nameEn: 'Coriander',
      group: CropGroup.herb,
      waterNoteTh: 'ประเมินความชื้นในวัสดุปลูกและหลีกเลี่ยงน้ำขัง',
      waterNoteEn: 'Assess growing-media moisture and avoid waterlogging.',
      lightNoteTh: 'ตรวจความร้อนและแสงในช่วงกลางวัน',
      lightNoteEn: 'Check midday heat and light.',
    ),
    CropProfile(
      id: 'custom',
      nameTh: 'กำหนดเอง',
      nameEn: 'Custom',
      group: CropGroup.custom,
      waterNoteTh: 'ใช้ข้อมูลจากเซนเซอร์และวัสดุปลูกจริงในการออกแบบค่าเริ่มและค่าหยุด',
      waterNoteEn: 'Use actual sensor and media observations to design start/stop targets.',
      lightNoteTh: 'กำหนดแผนดูแลตามชนิดพืชและบริบทของพื้นที่ปลูก',
      lightNoteEn: 'Design care conditions for the chosen crop and site.',
    ),
  ];

  static CropProfile? byId(String id) {
    for (final profile in profiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  static List<CropProfile> search(String query, {bool isThai = true}) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return profiles;
    return profiles
        .where(
          (profile) =>
              profile.id.contains(needle) ||
              profile.nameTh.toLowerCase().contains(needle) ||
              profile.nameEn.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }
}
