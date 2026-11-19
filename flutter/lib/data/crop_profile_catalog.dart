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
      referenceClimate: CropClimateReference(
        temperatureMinC: 25,
        temperatureMaxC: 30,
        sourceTitleTh: 'World Vegetable Center (AVRDC)',
        sourceTitleEn: 'World Vegetable Center',
        sourceUrl: 'https://worldveg.tind.io/record/39509',
        contextTh: 'ช่วงอุณหภูมิเฉลี่ยสำหรับผักบุ้งเขตร้อนชื้น ปรับตามชนิดผักบุ้งและฤดูกาล',
        contextEn: 'Average warm-humid tropics range; adjust for water spinach variety',
      ),
      sourceReferences: <String>['https://worldveg.tind.io/record/39509'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 10,
        temperatureMaxC: 20,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน ไม่ใช่เกณฑ์สั่งปั๊ม',
        contextEn: 'Greenhouse air-temperature reference; not an irrigation setpoint',
      ),
      sourceReferences: <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 18,
        temperatureMaxC: 24,
        sourceTitleTh: 'กรมส่งเสริมการเกษตร',
        sourceTitleEn: 'Thailand Department of Agricultural Extension',
        sourceUrl: 'https://esc.doae.go.th/การผลิตเมล็ดพันธุ์คะน้/',
        contextTh: 'ช่วงอุณหภูมิที่เหมาะสมต่อการปลูกคะน้า',
        contextEn: 'Suitable air temperature for Chinese kale cultivation',
      ),
      sourceReferences: <String>['https://esc.doae.go.th/การผลิตเมล็ดพันธุ์คะน้/'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 25,
        sourceTitleTh: 'สำนักงานปลัดกระทรวงเกษตรฯ',
        sourceTitleEn: 'Thailand Ministry of Agriculture',
        sourceUrl: 'https://www.opsmoac.go.th/chumphon-dwl-preview-441491791833',
        contextTh: 'ช่วงอุณหภูมิสำหรับผักกวางตุ้งทั่วไป (พันธุ์ปลูกมีผล)',
        contextEn: 'Typical bok choy cultivation range; variety matters',
      ),
      sourceReferences: <String>['https://www.opsmoac.go.th/chumphon-dwl-preview-441491791833'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 30,
        sourceTitleTh: 'สำนักงานปลัดกระทรวงเกษตรฯ',
        sourceTitleEn: 'Thailand Ministry of Agriculture',
        sourceUrl: 'https://www.opsmoac.go.th/pattani-local_wisdom-preview-472891791898',
        contextTh: 'ช่วงอุณหภูมิสำหรับพริกทั่วไป ไม่รวมพริกหวาน',
        contextEn: 'Typical chili peppers, excluding sweet/bell peppers',
      ),
      sourceReferences: <String>['https://www.opsmoac.go.th/pattani-local_wisdom-preview-472891791898'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 19,
        temperatureMaxC: 24,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน อาจต่างตามระยะปลูก',
        contextEn: 'Greenhouse air-temperature guidance; varies by growth stage',
      ),
      sourceReferences: <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 28,
        sourceTitleTh: 'Plants For A Future (PFAF)',
        sourceTitleEn: 'Plants For A Future',
        sourceUrl: 'https://pfaf.org/user/Plant.aspx?LatinName=Ocimum+tenuiflorum',
        contextTh: 'ช่วงอุณหภูมิกลางวันอ้างอิงของ Ocimum tenuiflorum จากฐานข้อมูลพืช',
        contextEn: 'Reference daytime growing temperatures for Ocimum tenuiflorum',
      ),
      sourceReferences: <String>['https://pfaf.org/user/Plant.aspx?LatinName=Ocimum+tenuiflorum'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 25,
        sourceTitleTh: 'University of Georgia Extension',
        sourceTitleEn: 'University of Georgia Extension',
        sourceUrl: 'https://fieldreport.caes.uga.edu/publications/B1595/controlled-environment-agriculture-basics/',
        contextTh: 'ค่ากลุ่มเบซิล/สมุนไพรสำหรับโรงเรือน ไม่ใช่ค่าที่วิจัยเฉพาะโหระพาไทย',
        contextEn: 'General culinary-basil greenhouse reference, not Thai-basil-specific',
      ),
      sourceReferences: <String>['https://fieldreport.caes.uga.edu/publications/B1595/controlled-environment-agriculture-basics/'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 20,
        temperatureMaxC: 24,
        sourceTitleTh: 'งานวิจัย Energy & Greenhouse',
        sourceTitleEn: 'Energies greenhouse study',
        sourceUrl: 'https://www.mdpi.com/1996-1073/16/19/6788',
        contextTh: 'ช่วงอุณหภูมิอากาศสำหรับการปลูกในโรงเรือน',
        contextEn: 'Greenhouse air-temperature reference',
      ),
      sourceReferences: <String>['https://www.mdpi.com/1996-1073/16/19/6788'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 25,
        temperatureMaxC: 35,
        sourceTitleTh: 'กระทรวงเกษตรรัฐออนแทรีโอ แคนาดา',
        sourceTitleEn: 'Ontario Ministry of Agriculture',
        sourceUrl: 'https://www.omafra.gov.on.ca/CropOp/en/spec_veg/pea_bean/yard.html',
        contextTh: 'ช่วงอุณหภูมิที่เหมาะต่อการปลูกถั่วฝักยาว (ไม่ใช่อุณหภูมิดิน)',
        contextEn: 'Suitable growing temperature for yardlong bean, not soil temperature',
      ),
      sourceReferences: <String>['https://www.omafra.gov.on.ca/CropOp/en/spec_veg/pea_bean/yard.html'],
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
      referenceClimate: CropClimateReference(
        temperatureMinC: 11,
        temperatureMaxC: 20,
        sourceTitleTh: 'AHDB Horticulture สหราชอาณาจักร',
        sourceTitleEn: 'AHDB Horticulture',
        sourceUrl: 'https://horticulture.ahdb.org.uk/Contents/Item/Display/54882',
        contextTh: 'ช่วงอุณหภูมิเพื่อคุณภาพกลิ่นใบผักชีในสภาพปลูกแบบสหราชอาณาจักร อาจไม่ตรงกับอากาศไทย',
        contextEn: 'UK leaf-flavour quality reference, not necessarily appropriate for Thai outdoor climate',
      ),
      sourceReferences: <String>['https://horticulture.ahdb.org.uk/Contents/Item/Display/54882'],
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
