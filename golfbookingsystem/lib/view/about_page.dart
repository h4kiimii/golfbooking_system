import 'package:flutter/material.dart';

import '../services/app_language.dart';
import '../theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.language});

  final AppLanguage language;

  _AboutCopy get _copy {
    return language == AppLanguage.malay
        ? _AboutCopy.malay
        : _AboutCopy.english;
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          copy.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AboutSection(
                  icon: Icons.school_rounded,
                  title: copy.projectInformationTitle,
                  children: [Text(copy.projectInformation)],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.flag_rounded,
                  title: copy.purposeTitle,
                  children: [Text(copy.purpose)],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.calendar_month_rounded,
                  title: copy.developmentPeriodTitle,
                  children: [Text(copy.developmentPeriod)],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.warning_amber_rounded,
                  title: copy.noticeTitle,
                  children: [Text(copy.notice)],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.groups_rounded,
                  title: copy.developmentTeamTitle,
                  children: const [
                    _TeamMember(
                      name: 'Muhammad Hakimi Adly bin Hazlee',
                      id: 'D20231106511',
                    ),
                    _TeamMember(
                      name: 'Muhammad Adib bin Samsuri',
                      id: 'D20231106481',
                    ),
                    _TeamMember(
                      name: 'Waldan Aiman bin Nazri',
                      id: 'D20231106455',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.co_present_rounded,
                  title: copy.lecturerTitle,
                  children: const [Text('Encik Rasyidi bin Johan')],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.menu_book_rounded,
                  title: copy.courseTitle,
                  children: [
                    const Text('DTS3073'),
                    const SizedBox(height: 6),
                    Text(copy.courseName),
                  ],
                ),
                const SizedBox(height: 12),
                _AboutSection(
                  icon: Icons.code_rounded,
                  title: copy.technologiesTitle,
                  children: const [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Flutter')),
                        Chip(label: Text('Supabase')),
                        Chip(label: Text('PostgreSQL')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  copy.footer,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            ...children.map(
              (child) => DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  const _TeamMember({required this.name, required this.id});

  final String name;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(name), const SizedBox(height: 3), Text(id)],
      ),
    );
  }
}

class _AboutCopy {
  const _AboutCopy({
    required this.title,
    required this.projectInformationTitle,
    required this.projectInformation,
    required this.purposeTitle,
    required this.purpose,
    required this.developmentPeriodTitle,
    required this.developmentPeriod,
    required this.noticeTitle,
    required this.notice,
    required this.developmentTeamTitle,
    required this.lecturerTitle,
    required this.courseTitle,
    required this.courseName,
    required this.technologiesTitle,
    required this.footer,
  });

  final String title;
  final String projectInformationTitle;
  final String projectInformation;
  final String purposeTitle;
  final String purpose;
  final String developmentPeriodTitle;
  final String developmentPeriod;
  final String noticeTitle;
  final String notice;
  final String developmentTeamTitle;
  final String lecturerTitle;
  final String courseTitle;
  final String courseName;
  final String technologiesTitle;
  final String footer;

  static const english = _AboutCopy(
    title: 'About the Application',
    projectInformationTitle: 'Project Information',
    projectInformation:
        'This Web-Based Learning (WBL) project is part of the course DTS3073 - Mobile Application Design and Development at Universiti Pendidikan Sultan Idris (UPSI).',
    purposeTitle: 'Purpose',
    purpose:
        'This application has been developed for educational purposes only as part of the students\' academic project. It is intended to demonstrate the implementation of a golf driving range booking system and is not a commercial product.',
    developmentPeriodTitle: 'Development Period',
    developmentPeriod:
        'The project will be developed during Semester 6 of the 2026 academic session, starting from Week 7 and continuing until Week 14, where it will be completed.',
    noticeTitle: 'Notice',
    notice:
        'This application was developed for academic and Work-Based Learning (WBL) purposes. Any request related to maintenance, system modification, feature enhancement, technical support, data management, or further development after Week 15 should be referred to the Faculty of Computing and Meta Technology (META), Universiti Pendidikan Sultan Idris (UPSI).',
    developmentTeamTitle: 'Development Team',
    lecturerTitle: 'Course Lecturer',
    courseTitle: 'Course',
    courseName: 'Mobile Application Design and Development',
    technologiesTitle: 'Technologies',
    footer:
        '© Work-Based Learning (WBL) Project 2026\nFaculty of Computing and Meta-Technology (META)\nUniversiti Pendidikan Sultan Idris (UPSI)',
  );

  static const malay = _AboutCopy(
    title: 'Tentang Aplikasi',
    projectInformationTitle: 'Maklumat Projek',
    projectInformation:
        'Projek Pembelajaran Berasaskan Kerja (WBL) ini merupakan sebahagian daripada kursus DTS3073 - Reka Bentuk dan Pembangunan Aplikasi Mudah Alih di Universiti Pendidikan Sultan Idris (UPSI).',
    purposeTitle: 'Tujuan',
    purpose:
        'Aplikasi ini dibangunkan untuk tujuan pendidikan sahaja sebagai sebahagian daripada projek akademik pelajar. Aplikasi ini bertujuan untuk menunjukkan pelaksanaan sistem tempahan lapang sasar golf dan bukan merupakan produk komersial.',
    developmentPeriodTitle: 'Tempoh Pembangunan',
    developmentPeriod:
        'Projek ini akan dibangunkan pada Semester 6 sesi akademik 2026, bermula dari Minggu 7 dan diteruskan sehingga Minggu 14, iaitu minggu projek ini akan disiapkan.',
    noticeTitle: 'Notis',
    notice:
        'Aplikasi ini dibangunkan untuk tujuan akademik dan Pembelajaran Berasaskan Kerja (WBL). Sebarang permintaan berkaitan penyelenggaraan, pengubahsuaian sistem, penambahbaikan ciri, sokongan teknikal, pengurusan data, atau pembangunan lanjut selepas Minggu 15 hendaklah dirujuk kepada Fakulti Komputeran dan Meta-Teknologi (META), Universiti Pendidikan Sultan Idris (UPSI).',
    developmentTeamTitle: 'Pasukan Pembangunan',
    lecturerTitle: 'Pensyarah Kursus',
    courseTitle: 'Kursus',
    courseName: 'Reka Bentuk dan Pembangunan Aplikasi Mudah Alih',
    technologiesTitle: 'Teknologi',
    footer:
        '© Projek Pembelajaran Berasaskan Kerja (WBL) 2026\nFakulti Komputeran dan Meta-Teknologi (META)\nUniversiti Pendidikan Sultan Idris (UPSI)',
  );
}
