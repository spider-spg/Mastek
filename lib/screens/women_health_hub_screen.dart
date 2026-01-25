import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:symptom_checker/l10n/app_localizations.dart';

import '../models/symptom_model.dart';
import '../services/locale_controller.dart';
import '../widgets/language_picker_sheet.dart';

class WomenHealthHubScreen extends StatelessWidget {
	const WomenHealthHubScreen({super.key});

	static const Color _primary = Color(0xFFC76B99);
	static const Color _secondary = Color(0xFF6CC7E3);
	static const Color _bgLight = Color(0xFFF0F9FF);
	static const Color _bgDark = Color(0xFF1E1419);
	static const Color _textLight = Color(0xFF181114);
	static const Color _mutedLight = Color(0xFF875E73);

	@override
	Widget build(BuildContext context) {
		assert(() {
			debugPrint('WomenHealthHubScreen.build');
			return true;
		}());

		final theme = Theme.of(context);
		final isDark = theme.brightness == Brightness.dark;
		final l10n = AppLocalizations.of(context);
		final model = context.watch<SymptomModel>();
		final localeController = context.watch<LocaleController>();

		final bg = isDark ? _bgDark : _bgLight;
		final card = isDark ? const Color(0xFF18181B) : Colors.white;
		final border = isDark ? const Color(0xFF27272A) : Colors.white;
		final textColor = isDark ? Colors.white : _textLight;
		final muted = isDark ? const Color(0xFFA1A1AA) : _mutedLight;

		return Scaffold(
			backgroundColor: bg,
			floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
			floatingActionButton: FloatingActionButton.extended(
				onPressed: () => Navigator.of(context).pushNamed('/chat'),
				backgroundColor: _primary,
				foregroundColor: Colors.white,
				elevation: 6,
				icon: const Icon(Icons.forum_rounded),
				label: Text(l10n.talkToMaya, style: const TextStyle(fontWeight: FontWeight.w900)),
			),
			body: SafeArea(
				child: Center(
					child: ConstrainedBox(
						constraints: const BoxConstraints(maxWidth: 420),
						child: CustomScrollView(
							slivers: [
								SliverAppBar(
									pinned: true,
									elevation: 0,
									backgroundColor: bg.withOpacity(0.80),
									surfaceTintColor: Colors.transparent,
									automaticallyImplyLeading: false,
									toolbarHeight: 92,
									titleSpacing: 0,
									title: Padding(
										padding: const EdgeInsets.only(left: 24),
										child: _Header(textColor: textColor, muted: muted),
									),
									actions: [
										Padding(
											padding: const EdgeInsets.only(right: 24),
											child: _TranslateButton(
												isDark: isDark,
												textColor: textColor,
												onTap: () async {
													final picked = await showLanguagePickerSheet(
														context,
														currentCode: model.selectedLanguage,
													);
													if (picked == null || picked == model.selectedLanguage) return;
													await model.setLanguage(picked);
													if (!context.mounted) return;
													await localeController.setFromLanguageCode(picked);
													if (!context.mounted) return;
													ScaffoldMessenger.of(context).showSnackBar(
														SnackBar(content: Text(l10n.languageSetTo(languageLabel(picked)))),
													);
												},
											),
										),
									],
									flexibleSpace: ClipRect(
										child: BackdropFilter(
											filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
											child: Container(color: Colors.transparent),
										),
									),
								),

								SliverToBoxAdapter(
									child: Padding(
										padding: const EdgeInsets.fromLTRB(24, 32, 24, 110),
										child: Column(
											children: [
												Text(
													l10n.womensHealthHubWelcome,
													textAlign: TextAlign.center,
													style: theme.textTheme.headlineSmall?.copyWith(
														fontWeight: FontWeight.w900,
														height: 1.15,
														letterSpacing: -0.2,
														color: textColor,
													),
												),
												const SizedBox(height: 10),
												Text(
													l10n.womensHealthHubSubtitle,
													textAlign: TextAlign.center,
													style: theme.textTheme.bodyLarge?.copyWith(
														color: muted,
														height: 1.5,
														fontWeight: FontWeight.w600,
													),
												),
												const SizedBox(height: 28),

												_CategoryCard(
													isDark: isDark,
													card: card,
													border: border,
													textColor: textColor,
													muted: muted,
													icon: Icons.calendar_today_rounded,
													title: l10n.menstrualHealth,
													description: l10n.womensHealthCategoryMenstrualDescription,
													recommended: true,
													onExplore: () => Navigator.of(context, rootNavigator: true).pushNamed('/menstrual-health'),
												),
												const SizedBox(height: 24),
												_CategoryCard(
													isDark: isDark,
													card: card,
													border: border,
													textColor: textColor,
													muted: muted,
													icon: Icons.child_care_rounded,
													title: l10n.pregnancyAndMaternal,
													description: l10n.womensHealthCategoryPregnancyDescription,
													onExplore: () => _snack(context, l10n.comingSoon),
												),
												const SizedBox(height: 24),
												_CategoryCard(
													isDark: isDark,
													card: card,
													border: border,
													textColor: textColor,
													muted: muted,
													icon: Icons.monitor_heart_rounded,
													title: l10n.breastHealth,
													description: l10n.womensHealthCategoryBreastDescription,
													onExplore: () => _snack(context, l10n.comingSoon),
												),
											],
										),
									),
								),
							],
						),
					),
				),
			),
		);
	}

	static void _snack(BuildContext context, String msg) {
		ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
	}
}

class _Header extends StatelessWidget {
	const _Header({required this.textColor, required this.muted});

	final Color textColor;
	final Color muted;

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context);
		return Row(
			children: [
				Container(
					width: 44,
					height: 44,
					decoration: BoxDecoration(
						color: WomenHealthHubScreen._secondary.withOpacity(0.20),
						borderRadius: BorderRadius.circular(18),
					),
					child: Icon(
						Icons.health_and_safety_rounded,
						color: WomenHealthHubScreen._secondary,
						size: 26,
					),
				),
				const SizedBox(width: 12),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						mainAxisAlignment: MainAxisAlignment.center,
						children: [
							Text(
								l10n.womensHealthHubTitle,
								maxLines: 1,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(
									fontSize: 20,
									fontWeight: FontWeight.w900,
									letterSpacing: -0.2,
									color: textColor,
									height: 1.0,
								),
							),
							const SizedBox(height: 2),
							Text(
								l10n.womensHealthHubTagline,
								style: TextStyle(
									fontSize: 10,
									fontWeight: FontWeight.w900,
									letterSpacing: 2.0,
									color: muted,
								),
							),
						],
					),
				),
			],
		);
	}
}

class _TranslateButton extends StatelessWidget {
	const _TranslateButton({required this.isDark, required this.textColor, required this.onTap});

	final bool isDark;
	final Color textColor;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final bg = isDark ? const Color(0xFF27272A) : Colors.white;
		return Material(
			color: bg,
			shape: const CircleBorder(),
			child: InkWell(
				customBorder: const CircleBorder(),
				onTap: onTap,
				child: Container(
					width: 40,
					height: 40,
					decoration: BoxDecoration(
						shape: BoxShape.circle,
						border: Border.all(color: WomenHealthHubScreen._secondary.withOpacity(0.10)),
						boxShadow: [
							BoxShadow(
								color: Colors.black.withOpacity(isDark ? 0.0 : 0.08),
								blurRadius: 10,
								offset: const Offset(0, 4),
							),
						],
					),
					child: Icon(Icons.translate_rounded, color: textColor, size: 22),
				),
			),
		);
	}
}

class _CategoryCard extends StatelessWidget {
	const _CategoryCard({
		required this.isDark,
		required this.card,
		required this.border,
		required this.textColor,
		required this.muted,
		required this.icon,
		required this.title,
		required this.description,
		required this.onExplore,
		this.recommended = false,
	});

	final bool isDark;
	final Color card;
	final Color border;
	final Color textColor;
	final Color muted;
	final IconData icon;
	final String title;
	final String description;
	final VoidCallback onExplore;
	final bool recommended;

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final l10n = AppLocalizations.of(context);
		return Container(
			decoration: BoxDecoration(
				color: card,
				borderRadius: BorderRadius.circular(28),
				border: Border.all(color: border),
				boxShadow: [
					BoxShadow(
						color: WomenHealthHubScreen._secondary.withOpacity(0.10),
						blurRadius: 24,
						offset: const Offset(0, 10),
					),
				],
			),
			child: Padding(
				padding: const EdgeInsets.all(24),
				child: Row(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Container(
							width: 64,
							height: 64,
							decoration: BoxDecoration(
								color: WomenHealthHubScreen._secondary.withOpacity(0.10),
								borderRadius: BorderRadius.circular(20),
							),
							child: Icon(icon, color: WomenHealthHubScreen._secondary, size: 34),
						),
						const SizedBox(width: 14),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										title,
										style: theme.textTheme.titleMedium?.copyWith(
											fontSize: 16,
											fontWeight: FontWeight.w800,
											color: textColor,
											height: 1.15,
										),
									),
									const SizedBox(height: 6),
									Text(
										description,
										style: theme.textTheme.bodyMedium?.copyWith(
											fontSize: 13,
											fontWeight: FontWeight.w600,
											color: muted,
											height: 1.55,
										),
									),
									const SizedBox(height: 18),
									Row(
										children: [
											Expanded(
												child: recommended
													? Row(
														children: [
															Icon(Icons.star_rounded, size: 18, color: WomenHealthHubScreen._secondary),
															const SizedBox(width: 6),
															Flexible(
																child: Text(
																	l10n.recommended,
																	maxLines: 1,
																	overflow: TextOverflow.ellipsis,
																	style: theme.textTheme.labelMedium?.copyWith(
																		fontSize: 11,
																		fontWeight: FontWeight.w800,
																		color: WomenHealthHubScreen._secondary,
																	),
																),
															),
														],
													)
													: const SizedBox.shrink(),
											),
											const SizedBox(width: 12),
											_ExploreButton(onTap: onExplore),
										],
									),
								],
							),
						),
					],
				),
			),
		);
	}
}

class _ExploreButton extends StatelessWidget {
	const _ExploreButton({required this.onTap});

	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context);
		return Container(
			decoration: BoxDecoration(
				color: WomenHealthHubScreen._primary,
				borderRadius: BorderRadius.circular(16),
				boxShadow: [
					BoxShadow(
						color: WomenHealthHubScreen._primary.withOpacity(0.20),
						blurRadius: 18,
						offset: const Offset(0, 10),
					),
				],
			),
			child: Material(
				color: Colors.transparent,
				child: InkWell(
					borderRadius: BorderRadius.circular(16),
					onTap: onTap,
					child: Padding(
						padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
						child: Text(
							l10n.explore,
							style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
						),
					),
				),
			),
		);
	}
}
