const mongoose = require('mongoose');
const LibraryItem = require('../models/LibraryItem');

const items = [
  {
    title: 'Học chữ khmer',
    type: 'Sách',
    description: 'Học bảng chữ cái và cách phát âm cơ bản',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781825/khmerkid/library/eddtrctzrddpea2mtfx1.png',
    rating: 4.8,
    views: 1200
  },
  {
    title: 'TRuyện thiếu nhi',
    type: 'Sách',
    description: 'Các câu chuyện ý nghĩa cho bé học tập',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png',
    rating: 4.9,
    views: 850
  },
  {
    title: 'Bé Tập Viết Chữ Khmer',
    type: 'Sách',
    description: 'Tập tô nét chữ Khmer chuẩn tiểu học',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781835/khmerkid/library/fof6w2jwtpitzj32vqus.png',
    rating: 4.7,
    views: 950
  },
  {
    title: 'Học Từ Vựng Khmer Qua Hình Ảnh',
    type: 'Sách',
    description: 'Học từ vựng trực quan sinh động qua tranh vẽ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781824/khmerkid/library/mtcq0mpsgjw65ey8fsbg.png',
    rating: 4.8,
    views: 1100
  },
  {
    title: 'ដំរីតូចក្លាហាន',
    type: 'Sách',
    description: 'Câu chuyện về lòng dũng cảm của chú voi nhỏ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
    rating: 4.9,
    views: 720,
    pages: [
      {
        textKhmer: 'កាលពីព្រេងនាយ មានកូនដំរីមួយ រស់នៅក្នុងព្រៃធំ។\nកូនដំរីនោះមានឈ្មោះថា ម៉ាំបូ។\nម៉ាំបូជាសត្វដំរីតូចមួយ ប៉ុន្តែមានចិត្តក្លាហានណាស់។',
        textVietnamese: 'Ngày xửa ngày xưa, có một chú voi con sống trong một khu rừng lớn.\nChú voi con đó tên là Mambo.\nMambo là một chú voi nhỏ nhưng rất dũng cảm.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
        highlights: ['ដំរី', 'ព្រៃធំ', 'ក្លាហាន']
      },
      {
        textKhmer: 'ថ្ងៃមួយ មានសត្វតោសាហាវមួយចង់ចាប់សត្វព្រៃ។\nកូនដំរីតូច ម៉ាំបូ មិនខ្លាចញញើតឡើយ។\nវាបានស្រែកបន្លឺសំឡេងយ៉ាងខ្លាំងដើម្បីការពារមិត្តភក្តិ។',
        textVietnamese: 'Một ngày nọ, có một con sư tử hung dữ muốn bắt các loài thú rừng.\nChú voi con Mambo không hề sợ hãi.\nChú đã rống lên thật to để bảo vệ các bạn của mình.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
        highlights: ['សាហាវ', 'កូនដំរី', 'ការពារ']
      }
    ]
  },
  {
    title: 'Thỏ Trắng Và Ngôi Sao May Mắn',
    type: 'Sách',
    description: 'Câu chuyện thỏ trắng tìm ngôi sao may mắn',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png',
    rating: 4.8,
    views: 640
  },
  {
    title: 'Hành Trình Tìm Cầu Vồng Của Bé Sóc',
    type: 'Sách',
    description: 'Cuộc phiêu lưu kỳ thú của chú sóc nhỏ',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781827/khmerkid/library/fytoyjalak42cfisfg3d.png',
    rating: 4.7,
    views: 580
  },
  {
    title: 'ស្វាតូចឆ្លាតវៃ',
    type: 'Sách',
    description: 'Câu chuyện thông minh dí dỏm về chú khỉ con',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781833/khmerkid/library/c42qxbcimdhz4am2ywes.png',
    rating: 4.9,
    views: 890
  },
  {
    title: 'ទន្សាយនិងអណ្តើក',
    type: 'Sách',
    description: 'Truyện ngụ ngôn Rùa và Thỏ bằng tiếng Khmer',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
    rating: 4.8,
    views: 1200,
    pages: [
      {
        textKhmer: 'ថ្ងៃមួយ ទន្សាយ បានជួប អណ្តើក។\nមានទន្សាយ បាននិយាយថា៖\n“ខ្ញុំរត់លឿនជាងអ្នក!”\nអណ្តើក បានឆ្លើយថា៖\n“យើងសាកប្រណាំងគ្នាទៅ!”',
        textVietnamese: 'Một ngày nọ, Thỏ gặp Rùa.\nThỏ nói:\n“Tôi chạy nhanh hơn bạn!”\nRùa trả lời:\n“Chúng ta hãy thi chạy nhé!”',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'អណ្តើក', 'រត់លឿន']
      },
      {
        textKhmer: 'ទន្សាយ បានសើចចំអកឱ្យអណ្តើកយ៉ាងខ្លាំង។\nវាបានយល់ព្រមភ្លាមៗចំពោះการប្រណាំងនេះ។\nសត្វផ្សេងទៀតនៅក្នុងព្រៃបានមកធ្វើជាសាក្សី។',
        textVietnamese: 'Thỏ bật cười chế giễu Rùa một cách dữ dội.\nNó lập tức đồng ý cuộc thi chạy này.\nCác loài vật khác trong rừng đã đến để làm chứng.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'អណ្តើក', 'សើចចំអក']
      },
      {
        textKhmer: 'ការប្រណាំងបានចាប់ផ្តើម។\nទន្សាយ បានរត់យ៉ាងលឿនដូចខ្យល់ព្យុះ។\nក្នុងមួយប៉ប្រិចភ្នែក វារត់ទៅបាត់យ៉ាងឆ្ងាយ។',
        textVietnamese: 'Cuộc đua bắt đầu.\nThỏ chạy nhanh như một cơn gió.\nChỉ trong chớp mắt, nó đã chạy biến đi thật xa.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ការប្រណាំង', 'ទន្សាយ', 'លឿន']
      },
      {
        textKhmer: 'អណ្តើក មិនអស់សង្ឃឹមឡើយ។\nវាដើរមួយជំហានម្តងៗ យឺតៗ ប៉ុន្តែច្បាស់លាស់។\nវាមិនព្រមឈប់សម្រាកឡើយ。',
        textVietnamese: 'Rùa không hề nản lòng.\nNó bước đi từng bước một, chậm rãi nhưng chắc chắn.\nNó quyết không dừng lại nghỉ ngơi.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['អណ្តើក', 'យឺតៗ', 'không dừng']
      },
      {
        textKhmer: 'បន្ទាប់ពីរត់បានពាក់កណ្តាលផ្លូវ ទន្សាយ បានងាកក្រោយ។\nវាឃើញ អណ្តើក នៅឆ្ងាយណាស់ ស្ទើរមើល không ឃើញ។\nទន្សាយ គិតថា ខ្លួនប្រាកដជាឈ្នះ。',
        textVietnamese: 'Sau khi chạy được nửa đường, Thỏ ngoảnh lại nhìn.\nNó thấy Rùa còn ở rất xa, gần như không nhìn thấy nữa.\nThỏ nghĩ rằng mình chắc chắn sẽ thắng.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'អណ្តើក', 'ឈ្នះ']
      },
      {
        textKhmer: 'ទន្សាយ ឃើញដើមឈើធំមួយ ដែលមានម្លប់ត្រជាក់។\nវាសម្រេចចិត្តសម្រាកនៅក្រោមដើមឈើនោះ។\nវាគិតថា ទោះបីជាគេងមួយ ស្របក់ក៏នៅតែឈ្នះដែរ。',
        textVietnamese: 'Thỏ thấy một cây to có bóng mát mát rượi.\nNó quyết định nghỉ ngơi dưới gốc cây đó.\nNó nghĩ dù có ngủ một lát thì vẫn sẽ thắng.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'ដើមឈើ', 'សម្រាក']
      },
      {
        textKhmer: 'មិនយូរប៉ុន្មាន ទន្សាយ ក៏បានលង់លក់យ៉ាងស្កប់ស្កល់។\nវាបានគេងលក់យ៉ាងស្រួលក្រោមខ្យល់បក់ត្រជាក់។\nវាស្រមៃឃើញខ្លួនឯងទទួលបានជ័យជំនះ。',
        textVietnamese: 'Chẳng bao lâu sau, Thỏ đã ngủ thiếp đi ngon lành.\nNó ngủ rất say dưới làn gió mát rượi.\nNó mơ thấy mình giành được chiến thắng.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'គេងលក់', 'ជ័យជំនះ']
      },
      {
        textKhmer: 'ខណៈពេលដែល ទន្សាយ កំពុងគេងលក់ អណ្តើក នៅតែបន្តដើរ។\nវាមិនខ្វល់ពីភាពហត់នឿយ ឬភាពយឺតយ៉ាវរបស់ខ្លួនឡើយ។\nវាដើរទៅមុខដោយការតាំងចិត្តខ្ពស់。',
        textVietnamese: 'Trong lúc Thỏ đang ngủ say, Rùa vẫn tiếp tục bước đi.\nNó không màng đến sự mệt mỏi hay sự chậm chạp của mình.\nNó đi về phía trước với quyết tâm cao.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'អណ្តើក', 'ដើរ']
      },
      {
        textKhmer: 'ទីបំផុត អណ្តើក បានដើរកាត់ ទន្សាយ ដែលកំពុងគេងលក់។\nអណ្តើក ដើរទៅមុខដោយស្ងៀមស្ងាត់បំផុត។\nទន្សាយ នៅតែគេងលក់យ៉ាងស្កប់ស្កល់ មិនដឹងខ្លួនឡើយ。',
        textVietnamese: 'Cuối cùng, Rùa đã đi qua chỗ Thỏ đang ngủ say.\nRùa bước đi một cách vô cùng lặng lẽ.\nThỏ vẫn ngủ say sưa, không hề hay biết gì.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['អណ្តើក', 'ទន្សាយ', 'គេងលក់']
      },
      {
        textKhmer: 'អណ្តើក បានដើរជិតដល់ទីព្រ័ត្រហើយ។\nសត្វទាំងអស់នៅក្នុងព្រៃចាប់ផ្តើមស្រែកហ៊ោរកញ្ជ្រៀវ។\nពួកគេលើកទឹកចិត្ត អណ្តើក យ៉ាងខ្លាំង。',
        textVietnamese: 'Rùa đã đi gần đến vạch đích rồi.\nTất cả muông thú trong rừng bắt đầu reo hò cổ vũ.\nHọ cổ vũ cho Rùa rất nhiệt tình.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['អណ្តើក', 'ទីព្រ័ត្រ', 'ស្រែកហ៊ោរ']
      },
      {
        textKhmer: 'សំឡេងហ៊ោរកញ្ជ្រៀវបានធ្វើឱ្យ ទន្សាយ ភ្ញាក់ពីគេង។\nវាក្រឡេកមើលទៅទីព្រ័ត្រ ហើយស្រឡាំងកាំង។\nវាឃើញ អណ្តើក ជិតដល់ទីព្រ័ត្របាត់ទៅហើយ。',
        textVietnamese: 'Tiếng reo hò náo nhiệt đã làm Thỏ thức giấc.\nNó nhìn về phía vạch đích và sửng sốt.\nNó thấy Rùa đã ở sát vạch đích mất rồi.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'ភ្ញាក់ពីគេង', 'អណ្តើក']
      },
      {
        textKhmer: 'ទន្សាយ បានស្ទុះរត់យ៉ាងលឿនបំផុត ប៉ុន្តែហួសពេលទៅហើយ។\nអណ្តើក បានដើរឆ្លងកាត់ទីព្រ័ត្រមុនគេ។\nអណ្តើក បានឈ្នះការប្រណាំងដោយសារការព្យាយាម。',
        textVietnamese: 'Thỏ vội vàng chạy hết sức bình sinh nhưng đã quá muộn.\nRùa đã bước qua vạch đích trước tiên.\nRùa đã chiến thắng cuộc đua nhờ sự kiên trì.',
        illustration: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781831/khmerkid/library/lfbcadvl5h22vh2rc6tv.png',
        highlights: ['ទន្សាយ', 'អណ្តើក', 'ឈ្នះ']
      }
    ]
  },
  {
    title: 'Bảng Chữ Cái Khmer Vui Nhộn',
    type: 'Sách',
    description: 'Học chữ cái qua các bài hát vui nhộn',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781822/khmerkid/library/zx2pibowpd287plq34sn.png',
    rating: 4.8,
    views: 910
  },
  {
    title: 'Hành Trình 33 Chữ Cái Khmer',
    type: 'Sách',
    description: 'Khám phá thế giới 33 chữ cái phụ âm',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781823/khmerkid/library/sh5oitnbnr3hhregxnor.png',
    rating: 4.9,
    views: 1500
  },
  {
    title: 'Bé Học Từ Vựng',
    type: 'Sách',
    description: 'Phát triển vốn từ vựng Khmer cơ bản hằng ngày',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png',
    rating: 4.7,
    views: 830
  },
  {
    title: 'ក្មេងៗ ច្រៀងលេង (Trẻ em ca hát vui đùa)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer vui nhộn dành cho bé',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781829/khmerkid/library/lhn2ivplvojj5mfayoia.png',
    rating: 4.9,
    views: 2500,
    duration: '02:35',
    lyrics: 'ក្មេងៗ ច្រៀងលេង ច្រៀងលេង\nសប្បាយ សប្បាយ សប្បាយណាស់\nយើងរាំ យើងច្រៀង\nសប្បាយណាស់ថ្ងៃនេះ!'
  },
  {
    title: 'ដំរីតូច (Chú voi con)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer về chú voi con ngộ nghĩnh',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781830/khmerkid/library/shzcfks9ptkmthq6wqp5.png',
    rating: 4.8,
    views: 1980,
    duration: '01:58',
    lyrics: 'ដំរី ដំរី ដំរីតូច\nមានច្រមុះវែង ត្រចៀកធំ\nដើរលេងក្នុងព្រៃជ្រៅ\nសប្បាយរីករាយណាស់!'
  },
  {
    title: 'គេងលក់ យប់នេះ (Đi ngủ nào bé ơi)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer ru bé giấc ngủ êm đềm',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781828/khmerkid/library/bxax1yqy9fde0pkqtxs5.png',
    rating: 4.7,
    views: 2120,
    duration: '02:12',
    lyrics: 'គេងលក់ គេងលក់ កូនសម្លាញ់\nយប់នេះមានផ្កាយភ្លឺល្អ\nបិទភ្នែកគេងលក់ទៅ\nយល់សប្តិឃើញរឿងល្អ។'
  },
  {
    title: ' ខ្ញុំស្រឡាញ់គ្រួសារ (Em yêu gia đình)',
    type: 'Audio',
    description: 'Bài hát tiếng Khmer ý nghĩa ca ngợi gia đình thân thương',
    image: 'https://res.cloudinary.com/dvnrhbazd/image/upload/f_auto,q_auto,w_300/v1781781820/khmerkid/library/dnakvq21vgkv0oabe4pw.png',
    rating: 4.9,
    views: 2480,
    duration: '02:48',
    lyrics: 'ខ្ញុំស្រឡាញ់ប៉ាម៉ាក់\nខ្ញុំស្រឡាញ់បងប្អូន\nគ្រួសារយើងសប្បាយ\nរស់នៅក្បែរគ្នានិច្ច។'
  },
  {
    title: 'Học nguyên âm tiếng Khmer',
    type: 'Video',
    description: 'Học nguyên âm qua video hoạt hình',
    image: 'image/Nguyên âm.png',
    rating: 4.7,
    views: 2100,
    duration: '08:45'
  },
  {
    title: 'Đếm số 1-10',
    type: 'Video',
    description: 'Nhận diện chữ số Khmer qua bài hát',
    image: 'image/Tập đọc.png',
    rating: 4.9,
    views: 3200,
    duration: '05:30'
  },
  {
    title: 'Giải cứu thú rừng',
    type: 'Video',
    description: 'Học từ vựng Khmer qua cuộc chiến bảo vệ rừng xanh',
    image: 'image/Giải cứu thú rừng.png',
    rating: 4.8,
    views: 1520,
    duration: '10:15'
  },
  {
    title: 'Đảo quốc Ngữ pháp',
    type: 'Video',
    description: 'Khám phá thế giới ngữ pháp Khmer qua chuyến đi phiêu lưu',
    image: 'image/Đảo quốc Ngữ pháp.png',
    rating: 4.9,
    views: 2350,
    duration: '12:40'
  },
  {
    title: 'Cờ tỷ phú Khmer kỳ thú',
    type: 'Video',
    description: 'Vừa chơi cờ vừa học giao tiếp tiếng Khmer thực tế',
    image: 'image/Cờ tỷ phú Khmer kỳ thú.png',
    rating: 4.7,
    views: 980,
    duration: '15:20'
  },
  {
    title: 'Nhà khảo cổ nhí',
    type: 'Video',
    description: 'Khám phá lịch sử cổ xưa qua các chữ cái Khmer',
    image: 'image/Nhà khảo cổ nhí.png',
    rating: 4.8,
    views: 1120,
    duration: '09:50'
  },
  {
    title: 'Bắt chữ Khmer',
    type: 'Video',
    description: 'Đố vui đoán chữ Khmer cực nhanh cho các bé học từ',
    image: 'image/Bắt chữ Khmer.png',
    rating: 4.9,
    views: 3080,
    duration: '11:05'
  }
];

const seedLibrary = async () => {
  try {
    console.log('🏁 Seeding Library items...');
    await LibraryItem.deleteMany({});
    console.log('🗑️ Cleared existing library items.');
    const result = await LibraryItem.insertMany(items);
    console.log(`✅ Successfully seeded ${result.length} library items.`);
  } catch (error) {
    console.error('❌ Seeding library items failed:', error.message);
  }
};

module.exports = seedLibrary;

if (require.main === module) {
  require('dotenv').config({ path: '../../.env' });
  const runDirectly = async () => {
    const mongoUri = process.env.MONGO_URI || 'mongodb+srv://admin:PCO6NePc2Gmcifzt@lamv.tzc1slv.mongodb.net/khmerkid';
    console.log('Connecting directly to MongoDB:', mongoUri);
    await mongoose.connect(mongoUri);
    await seedLibrary();
    await mongoose.connection.close();
    console.log('Direct execution complete.');
  };
  runDirectly();
}
