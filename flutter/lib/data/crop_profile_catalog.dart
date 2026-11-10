import '../models/crop_profile.dart';

/// Offline crop selection catalog. Verified climate ranges are advisory only;
/// no soil moisture thresholds, irrigation times, or pump commands are inferred.
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 10,
        temperatureMaxC: 20,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน ไม่ใช่เกณฑ์สั่งปั๊ม',
        contextEn: 'Greenhouse air-temperature reference; not an irrigation setpoint',
      ),
      sourceReferences: const <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 18,
        temperatureMaxC: 24,
        sourceTitleTh: 'กรมส่งเสริมการเกษตร',
        sourceTitleEn: 'Thailand Department of Agricultural Extension',
        sourceUrl: 'https://esc.doae.go.th/การผลิตเมล็ดพันธุ์คะน้/',
        contextTh: 'ช่วงอุณหภูมิที่เหมาะสมต่อการปลูกคะน้า',
        contextEn: 'Suitable air temperature for Chinese kale cultivation',
      ),
      sourceReferences: const <String>['https://esc.doae.go.th/การผลิตเมล็ดพันธุ์คะน้/'],
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 25,
        sourceTitleTh: 'สำนักงานปลัดกระทรวงเกษตรฯ',
        sourceTitleEn: 'Thailand Ministry of Agriculture',
        sourceUrl: 'https://www.opsmoac.go.th/chumphon-dwl-preview-441491791833',
        contextTh: 'ช่วงอุณหภูมิสำหรับผักกวางตุ้งทั่วไป (พันธุ์ปลูกมีผล)',
        contextEn: 'Typical bok choy cultivation range; variety matters',
      ),
      sourceReferences: const <String>['https://www.opsmoac.go.th/chumphon-dwl-preview-441491791833'],
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 30,
        sourceTitleTh: 'สำนักงานปลัดกระทรวงเกษตรฯ',
        sourceTitleEn: 'Thailand Ministry of Agriculture',
        sourceUrl: 'https://www.opsmoac.go.th/pattani-local_wisdom-preview-472891791898',
        contextTh: 'ช่วงอุณหภูมิสำหรับพริกทั่วไป ไม่รวมพริกหวาน',
        contextEn: 'Typical chili peppers, excluding sweet/bell peppers',
      ),
      sourceReferences: const <String>['https://www.opsmoac.go.th/pattani-local_wisdom-preview-472891791898'],
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 19,
        temperatureMaxC: 24,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน อาจต่างตามระยะปลูก',
        contextEn: 'Greenhouse air-temperature guidance; varies by growth stage',
      ),
      sourceReferences: const <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
      referenceClimate: const CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 24,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน',
        contextEn: 'Greenhouse air-temperature reference',
      ),
      sourceReferences: const <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
