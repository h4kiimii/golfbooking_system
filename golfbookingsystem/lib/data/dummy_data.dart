import '../model/booking.dart';
import '../model/driving_range_package.dart';
import '../model/trainer.dart';

class DummyData {
  static const drivingRangePackages = [
    DrivingRangePackage(
      name: '50-Ball Bucket',
      description: 'One bucket containing 50 driving-range balls.',
      nonMemberPrice: 'RM 10',
      memberPrice: 'RM 7.50',
      balls: 50,
    ),
    DrivingRangePackage(
      name: '100-Ball Bucket',
      description: 'One bucket containing 100 driving-range balls.',
      nonMemberPrice: 'RM 15',
      memberPrice: 'RM 13',
      balls: 100,
    ),
  ];

  static const trainers = [
    Trainer(
      name: 'Nordin bin Yahya',
      phoneNumber: '012 537 7396',
      email: null,
      description:
          'Specialist in beginner swing basics, stance correction, and driving accuracy.',
      level: 'Professional Amateur( Prof. Am.)',
    ),
    Trainer(
      name: 'Mohd Muhayyuddin bin Md Zain',
      phoneNumber: '011 6514 6767',
      email: 'dingolfzero@gmail.com',
      description:
          'Specialist in short game control, putting technique, and guided practice routine.',
      level: 'Professional Amateur( Prof. Am.)',
    ),
  ];

  static final sampleBookings = [
    Booking(
      id: 'B001',
      type: 'Golf Driving Range',
      title: '1 x 100-Ball Bucket (100 balls) - Member',
      date: DateTime(2026, 6, 20),
      time: '10:00 AM',
      amount: 'RM 13',
      paymentMethod: 'QR Payment',
      status: BookingStatus.confirmed,
      startTime: '10:00 AM',
      endTime: '11:00 AM',
      duration: '1 hour',
      durationMinutes: 60,
      lane: 'KD03',
      laneId: 'KD03',
      paymentReference: 'PAY-10000001',
      paymentReceiptName: 'receipt-b001.jpg',
      paymentReceiptUploadedAt: DateTime(2026, 6, 20, 9, 38),
      receiptNumber: 'RCP-2026062001',
      verifiedAt: DateTime(2026, 6, 20, 9, 45),
    ),
    Booking(
      id: 'B002',
      type: 'Golf Trainer',
      title: 'Mohd Muhayyuddin bin Md Zain',
      date: DateTime(2026, 6, 22),
      time: 'Arrange with trainer',
      amount: 'To be negotiated',
      paymentMethod: 'Arrange with trainer',
      status: BookingStatus.confirmed,
      startTime: 'Arrange with trainer',
      trainerPhoneNumber: '011 6514 6767',
      trainerEmail: 'dingolfzero@gmail.com',
      trainingClassType: 'Intermediate',
    ),
  ];

  static const availableTimes = [
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM',
    '8:00 PM',
    '9:00 PM',
    '10:00 PM',
  ];

  static const drivingRangeLanes = [
    'KD01',
    'KD02',
    'KD03',
    'KD04',
    'KD05',
    'KD06',
    'KD07',
    'KD08',
    'KD09',
    'KD10',
  ];

  static const paymentMethod = 'QR Payment';
  static const payAtCounter = 'Pay at Counter';
  static const paymentMethods = [paymentMethod, payAtCounter];
  static const qrPaymentData =
      'https://payment.upsi-driving-range.example/checkout';
}
