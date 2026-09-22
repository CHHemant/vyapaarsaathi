import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/credit_entry.dart';
import '../../providers/khata/khata_provider.dart';
import '../../theme/kirana_colors.dart';

class PartyLedgerScreen extends ConsumerStatefulWidget {
  const PartyLedgerScreen({super.key});

  @override
  ConsumerState<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends ConsumerState<PartyLedgerScreen> {
  String? _selectedCustomerId;
  int _selectedFilter = 0;
  String _searchQuery = '';

  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00');

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(khataEntriesProvider);

    return Scaffold(
      backgroundColor: KiranaColors.bg,
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _buildErrorState(error),
          data: _buildContent,
        ),
      ),
    );
  }

  Widget _buildContent(List<CreditEntry> entries) {
    final customers = _buildCustomerList(entries);

    final query = _searchQuery.trim().toLowerCase();

    final filteredCustomers = query.isEmpty
        ? customers
        : customers.where((customer) {
            return customer.name.toLowerCase().contains(query) ||
                customer.phone.toLowerCase().contains(query);
          }).toList();

    // Keep the currently selected customer valid.
    String? selectedCustomerId = _selectedCustomerId;

    if (selectedCustomerId == null && customers.isNotEmpty) {
      selectedCustomerId = customers.first.id;
    }

    final selectedCustomer = _findCustomer(
      customers,
      selectedCustomerId,
    );

    if (selectedCustomer == null && customers.isNotEmpty) {
      selectedCustomerId = customers.first.id;
    }

    final effectiveCustomer = _findCustomer(
      customers,
      selectedCustomerId,
    );

    final customerEntries = effectiveCustomer == null
        ? <CreditEntry>[]
        : entries
            .where(
              (entry) => entry.customerId == effectiveCustomer.id,
            )
            .toList()
      ..sort(
        (a, b) => b.date.compareTo(a.date),
      );

    final filteredEntries = _filterEntries(customerEntries);

    final totalReceivable = _calculateTotal(
      entries,
      type: 'given',
    );

    final totalPayable = _calculateTotal(
      entries,
      type: 'taken',
    );

    final totalOutstanding = totalReceivable - totalPayable;

    final activePartyIds = entries
        .where((entry) => entry.hasOutstanding)
        .map((entry) => entry.customerId)
        .toSet();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  150,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeading(),
                    const SizedBox(height: 20),
                    _buildOverviewCard(
                      totalReceivable,
                      totalPayable,
                      totalOutstanding,
                      activePartyIds.length,
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader(
                      title: 'PARTIES',
                      subtitle: '${customers.length} total',
                    ),
                    const SizedBox(height: 10),
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    if (filteredCustomers.isEmpty)
                      _buildNoPartiesState()
                    else
                      ...filteredCustomers.map(
                        (customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildPartyListCard(
                            customer,
                            entries,
                            isSelected: customer.id == effectiveCustomer?.id,
                          ),
                        ),
                      ),
                    if (effectiveCustomer != null) ...[
                      const SizedBox(height: 14),
                      _buildSelectedPartyHeader(
                        effectiveCustomer,
                      ),
                      const SizedBox(height: 12),
                      _buildFilterTabs(customerEntries),
                      const SizedBox(height: 14),
                      _buildEntriesSection(filteredEntries),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildBottomActions(effectiveCustomer),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: KiranaColors.bg,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            tooltip: 'Back',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: KiranaColors.onSurface,
            ),
            onPressed: () {
              Navigator.of(context).maybePop();
            },
          ),
        ),
      ),
      title: Text(
        'KHATA',
        style: GoogleFonts.bebasNeue(
          fontSize: 28,
          color: KiranaColors.primary,
          letterSpacing: 1,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () {
            ref.read(khataEntriesProvider.notifier).refresh();
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: KiranaColors.onSurface,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildPageHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: KiranaColors.secondary.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 14,
                color: KiranaColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'YOUR CREDIT LEDGER',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: KiranaColors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'PARTY LEDGER',
          style: GoogleFonts.bebasNeue(
            fontSize: 50,
            height: 0.9,
            color: KiranaColors.primary,
          ),
        ),
        Text(
          '& CLEARANCES',
          style: GoogleFonts.bebasNeue(
            fontSize: 50,
            height: 0.9,
            color: KiranaColors.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Know who owes you, whom you owe, and what still needs to be settled.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 1.5,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW
  // ---------------------------------------------------------------------------

  Widget _buildOverviewCard(
    double receivable,
    double payable,
    double outstanding,
    int activeParties,
  ) {
    final isPayable = outstanding < 0;
    final isSettled = outstanding == 0;

    final statusText = isSettled
        ? 'ALL SETTLED'
        : isPayable
            ? 'YOU WILL GIVE'
            : 'YOU WILL RECEIVE';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: KiranaColors.premiumGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: KiranaColors.primary.withValues(
              alpha: 0.14,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL OUTSTANDING',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white70,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$activeParties ACTIVE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '₹${_currencyFormat.format(outstanding.abs())}',
            style: GoogleFonts.bebasNeue(
              fontSize: 54,
              height: 1,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            statusText,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOverviewMetric(
                  label: 'TO RECEIVE',
                  amount: receivable,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white24,
              ),
              Expanded(
                child: _buildOverviewMetric(
                  label: 'TO GIVE',
                  amount: payable,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetric({
    required String label,
    required double amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_currencyFormat.format(amount)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION HEADER
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: KiranaColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: KiranaColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: KiranaColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Search party or phone number...',
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: KiranaColors.onSurfaceVariant,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: KiranaColors.onSurfaceVariant,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: KiranaColors.outlineVariant.withValues(
              alpha: 0.20,
            ),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: KiranaColors.outlineVariant.withValues(
              alpha: 0.20,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: KiranaColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PARTY LIST
  // ---------------------------------------------------------------------------

  Widget _buildPartyListCard(
    _CustomerSummary customer,
    List<CreditEntry> entries, {
    required bool isSelected,
  }) {
    final customerEntries = entries
        .where(
          (entry) => entry.customerId == customer.id,
        )
        .toList();

    final receivable = _calculateCustomerTotal(
      customerEntries,
      type: 'given',
    );

    final payable = _calculateCustomerTotal(
      customerEntries,
      type: 'taken',
    );

    final balance = receivable - payable;

    final isReceivable = balance > 0;
    final isPayable = balance < 0;

    final amountColor = balance == 0
        ? Colors.green.shade700
        : isPayable
            ? Colors.orange.shade800
            : KiranaColors.primary;

    final initials = _getInitials(customer.name);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            _selectedCustomerId = customer.id;
            _selectedFilter = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? KiranaColors.primary.withValues(
                      alpha: 0.55,
                    )
                  : KiranaColors.outlineVariant.withValues(
                      alpha: 0.20,
                    ),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: KiranaColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: KiranaColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: KiranaColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: KiranaColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${customerEntries.length} '
                      '${customerEntries.length == 1 ? 'entry' : 'entries'}'
                      '${customer.phone.isNotEmpty ? ' • ${customer.phone}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_currencyFormat.format(balance.abs())}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    balance == 0
                        ? 'SETTLED'
                        : isReceivable
                            ? 'RECEIVE'
                            : 'GIVE',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: KiranaColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SELECTED PARTY
  // ---------------------------------------------------------------------------

  Widget _buildSelectedPartyHeader(
    _CustomerSummary customer,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        13,
        14,
        13,
      ),
      decoration: BoxDecoration(
        color: KiranaColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 18,
            color: KiranaColors.primary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${customer.name.toUpperCase()} LEDGER',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.7,
                color: KiranaColors.onSurface,
              ),
            ),
          ),
          Text(
            'SELECTED',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: KiranaColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------------

  Widget _buildFilterTabs(
    List<CreditEntry> entries,
  ) {
    final allCount = entries.length;

    final receiveCount = entries
        .where(
          (entry) => entry.type == 'given' && entry.hasOutstanding,
        )
        .length;

    final giveCount = entries
        .where(
          (entry) => entry.type == 'taken' && entry.hasOutstanding,
        )
        .length;

    final settledCount = entries.where((entry) => entry.isPaid).length;

    final filters = [
      'ALL ($allCount)',
      'RECEIVE ($receiveCount)',
      'GIVE ($giveCount)',
      'SETTLED ($settledCount)',
    ];

    // Prevent an invalid filter index after provider updates.
    if (_selectedFilter >= filters.length) {
      _selectedFilter = 0;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          filters.length,
          (index) => Padding(
            padding: EdgeInsets.only(
              right: index == filters.length - 1 ? 0 : 8,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = index;
                });
              },
              child: _buildFilterChip(
                filters[index],
                active: _selectedFilter == index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label, {
    required bool active,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: active ? KiranaColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: active
              ? KiranaColors.primary
              : KiranaColors.outlineVariant.withValues(
                  alpha: 0.20,
                ),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: active ? Colors.white : KiranaColors.onSurface,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LEDGER ENTRIES
  // ---------------------------------------------------------------------------

  Widget _buildEntriesSection(
    List<CreditEntry> entries,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'LEDGER ACTIVITY',
          subtitle: '${entries.length} shown',
        ),
        const SizedBox(height: 10),
        if (entries.isEmpty)
          _buildNoEntriesState()
        else
          ...entries.map(_buildEntryCard),
      ],
    );
  }

  Widget _buildEntryCard(
    CreditEntry entry,
  ) {
    final isGiven = entry.type == 'given';
    final isPartiallyPaid = entry.isPartiallyPaid;
    final hasOutstanding = entry.hasOutstanding;

    final color = entry.isPaid
        ? Colors.green.shade700
        : isGiven
            ? KiranaColors.primary
            : Colors.orange.shade800;

    final backgroundColor = entry.isPaid
        ? Colors.green.withValues(alpha: 0.06)
        : isGiven
            ? KiranaColors.primary.withValues(alpha: 0.05)
            : Colors.orange.withValues(alpha: 0.06);

    final statusLabel = entry.isPaid
        ? 'PAID'
        : isPartiallyPaid
            ? 'PARTIAL'
            : 'DUE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  entry.isPaid
                      ? Icons.check_circle_outline_rounded
                      : isPartiallyPaid
                          ? Icons.timelapse_rounded
                          : isGiven
                              ? Icons.north_east_rounded
                              : Icons.south_west_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGiven ? 'You gave' : 'You got',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: KiranaColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.notes?.trim().isNotEmpty == true
                          ? entry.notes!.trim()
                          : 'Khata entry',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: KiranaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isGiven ? '+' : '-'}₹${_currencyFormat.format(entry.amount)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(
                    statusLabel,
                    color,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payment summary.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildPaymentMetric(
                    label: 'TOTAL',
                    amount: entry.amount,
                  ),
                ),
                Expanded(
                  child: _buildPaymentMetric(
                    label: 'PAID',
                    amount: entry.paidAmount,
                  ),
                ),
                Expanded(
                  child: _buildPaymentMetric(
                    label: hasOutstanding ? 'DUE' : 'REMAINING',
                    amount: entry.remainingAmount,
                    emphasize: hasOutstanding,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: KiranaColors.outlineVariant.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: KiranaColors.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
                Text(
                  DateFormat('dd MMM yyyy').format(entry.date),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: KiranaColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (hasOutstanding)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _recordPayment(entry),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: KiranaColors.primary.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        entry.paidAmount > 0 ? 'ADD PAYMENT' : 'RECORD PAYMENT',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: KiranaColors.primary,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    entry.paidAt == null
                        ? 'SETTLED'
                        : 'PAID ${DateFormat('dd MMM').format(entry.paidAt!)}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMetric({
    required String label,
    required double amount,
    bool emphasize = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: KiranaColors.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '₹${_currencyFormat.format(amount)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: emphasize ? KiranaColors.primary : KiranaColors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATES
  // ---------------------------------------------------------------------------

  Widget _buildNoPartiesState() {
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: KiranaColors.secondary.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.people_outline_rounded,
              size: 34,
              color: KiranaColors.secondary,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            hasSearch ? 'NO PARTY FOUND' : 'YOUR KHATA IS EMPTY',
            style: GoogleFonts.bebasNeue(
              fontSize: 24,
              color: KiranaColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hasSearch
                ? 'Try a different party name or phone number.'
                : 'Add your first You Gave or You Got entry to start tracking party dues.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              height: 1.5,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEntriesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: KiranaColors.outlineVariant.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 38,
            color: KiranaColors.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'NOTHING HERE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: KiranaColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another filter or add a new Khata entry.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: KiranaColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildBottomActions(
    _CustomerSummary? customer,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16,
        ),
        decoration: BoxDecoration(
          color: KiranaColors.bg.withValues(alpha: 0.97),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: _buildBottomButton(
                  label: 'YOU GAVE',
                  icon: Icons.north_east_rounded,
                  background: KiranaColors.primary,
                  foreground: Colors.white,
                  onPressed: () {
                    _openEntryForm(
                      type: 'given',
                      customer: customer,
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildBottomButton(
                  label: 'YOU GOT',
                  icon: Icons.south_west_rounded,
                  background: KiranaColors.tertiaryContainer,
                  foreground: KiranaColors.onSurface,
                  onPressed: () {
                    _openEntryForm(
                      type: 'taken',
                      customer: customer,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER / CALCULATION HELPERS
  // ---------------------------------------------------------------------------

  List<_CustomerSummary> _buildCustomerList(
    List<CreditEntry> entries,
  ) {
    final map = <String, _CustomerSummary>{};

    for (final entry in entries) {
      final customerId = entry.customerId.trim();

      if (customerId.isEmpty) {
        continue;
      }

      map[customerId] = _CustomerSummary(
        id: customerId,
        name: entry.customerName.trim().isEmpty
            ? 'Unknown Party'
            : entry.customerName.trim(),
        phone: entry.customerPhone.trim(),
      );
    }

    final customers = map.values.toList();

    customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
    );

    return customers;
  }

  _CustomerSummary? _findCustomer(
    List<_CustomerSummary> customers,
    String? customerId,
  ) {
    if (customerId == null) {
      return null;
    }

    for (final customer in customers) {
      if (customer.id == customerId) {
        return customer;
      }
    }

    return null;
  }

  double _calculateTotal(
    List<CreditEntry> entries, {
    required String type,
  }) {
    return entries
        .where(
          (entry) => entry.type == type && entry.hasOutstanding,
        )
        .fold<double>(
          0,
          (total, entry) => total + entry.remainingAmount,
        );
  }

  double _calculateCustomerTotal(
    List<CreditEntry> entries, {
    required String type,
  }) {
    return entries
        .where(
          (entry) => entry.type == type && entry.hasOutstanding,
        )
        .fold<double>(
          0,
          (total, entry) => total + entry.remainingAmount,
        );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    return parts
        .map(
          (part) => part.substring(0, 1),
        )
        .join()
        .toUpperCase();
  }

  List<CreditEntry> _filterEntries(
    List<CreditEntry> entries,
  ) {
    switch (_selectedFilter) {
      case 1:
        return entries
            .where(
              (entry) => entry.type == 'given' && entry.hasOutstanding,
            )
            .toList();

      case 2:
        return entries
            .where(
              (entry) => entry.type == 'taken' && entry.hasOutstanding,
            )
            .toList();

      case 3:
        return entries.where((entry) => entry.isPaid).toList();

      default:
        return List<CreditEntry>.from(entries);
    }
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> _recordPayment(
    CreditEntry entry,
  ) async {
    if (!entry.hasOutstanding) {
      return;
    }

    final controller = TextEditingController(
      text: entry.remainingAmount.toStringAsFixed(2),
    );

    try {
      final paymentAmount = await showDialog<double>(
        context: context,
        builder: (dialogContext) {
          final formKey = GlobalKey<FormState>();

          return AlertDialog(
            title: const Text('Record Payment'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.customerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Remaining: ₹${_currencyFormat.format(entry.remainingAmount)}',
                    style: const TextStyle(
                      color: KiranaColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Payment amount',
                      prefixIcon: Icon(
                        Icons.currency_rupee_rounded,
                      ),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        value?.replaceAll(',', '').trim() ?? '',
                      );

                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }

                      if (amount > entry.remainingAmount + 0.000001) {
                        return 'Cannot exceed remaining balance';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      controller.text =
                          entry.remainingAmount.toStringAsFixed(2);
                    },
                    icon: const Icon(
                      Icons.done_all_rounded,
                      size: 17,
                    ),
                    label: const Text('Pay full remaining amount'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  final amount = double.parse(
                    controller.text.replaceAll(',', '').trim(),
                  );

                  Navigator.of(dialogContext).pop(amount);
                },
                child: const Text('SAVE PAYMENT'),
              ),
            ],
          );
        },
      );

      if (paymentAmount == null || !mounted) {
        return;
      }

      await ref
          .read(khataEntriesProvider.notifier)
          .recordPayment(entry.id, paymentAmount);

      if (!mounted) {
        return;
      }

      final wasFullyPaid = paymentAmount >= entry.remainingAmount - 0.000001;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasFullyPaid
                ? 'Payment recorded. Khata entry is fully paid.'
                : 'Payment of ₹${_currencyFormat.format(paymentAmount)} recorded.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not record payment: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _openEntryForm({
    required String type,
    required _CustomerSummary? customer,
  }) async {
    final result = await showModalBottomSheet<CreditEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) {
        return _KhataEntrySheet(
          type: type,
          customer: customer,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await ref.read(khataEntriesProvider.notifier).addEntry(result);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCustomerId = result.customerId;
        _selectedFilter = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == 'given' ? 'You Gave entry added.' : 'You Got entry added.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save Khata entry: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR
  // ---------------------------------------------------------------------------

  Widget _buildErrorState(
    Object error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'KHATA COULD NOT BE LOADED',
              textAlign: TextAlign.center,
              style: GoogleFonts.bebasNeue(
                fontSize: 24,
                color: KiranaColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: KiranaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(khataEntriesProvider);
              },
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOMER SUMMARY
// =============================================================================

class _CustomerSummary {
  final String id;
  final String name;
  final String phone;

  const _CustomerSummary({
    required this.id,
    required this.name,
    required this.phone,
  });
}

// =============================================================================
// KHATA ENTRY SHEET
// =============================================================================

class _KhataEntrySheet extends StatefulWidget {
  final String type;
  final _CustomerSummary? customer;

  const _KhataEntrySheet({
    required this.type,
    required this.customer,
  });

  @override
  State<_KhataEntrySheet> createState() => _KhataEntrySheetState();
}

class _KhataEntrySheetState extends State<_KhataEntrySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  DateTime _selectedDate = DateTime.now();

  bool get isGiven => widget.type == 'given';

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.customer?.name ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.customer?.phone ?? '',
    );

    _amountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  String _createCustomerId(
    String name,
    String phone,
  ) {
    final normalized = '${name.trim().toLowerCase()}_'
        '${phone.replaceAll(RegExp(r'\D'), '')}';

    var hash = 0;

    for (final codeUnit in normalized.codeUnits) {
      hash = ((hash << 5) - hash + codeUnit) & 0x7fffffff;
    }

    return 'party_$hash';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );

    if (amount == null || amount <= 0) {
      return;
    }

    final customerId = widget.customer?.id ??
        _createCustomerId(
          name,
          phone,
        );

    final entry = CreditEntry(
      id: 'khata_${DateTime.now().microsecondsSinceEpoch}',
      customerId: customerId,
      customerName: name,
      customerPhone: phone,
      amount: amount,
      type: widget.type,
      date: _selectedDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(entry);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        bottomInset + 18,
      ),
      decoration: const BoxDecoration(
        color: KiranaColors.bg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isGiven ? 'YOU GAVE ₹' : 'YOU GOT ₹',
                style: GoogleFonts.bebasNeue(
                  fontSize: 34,
                  color: isGiven ? KiranaColors.primary : Colors.green.shade700,
                ),
              ),
              Text(
                isGiven
                    ? 'Record credit given to a party.'
                    : 'Record money received from a party.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: KiranaColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              _buildField(
                controller: _nameController,
                label: 'PARTY NAME',
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter party name';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _phoneController,
                label: 'PHONE',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _amountController,
                label: 'AMOUNT',
                icon: Icons.currency_rupee_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    value?.replaceAll(',', '').trim() ?? '',
                  );

                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _notesController,
                label: 'NOTE (OPTIONAL)',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildDatePicker(),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isGiven ? KiranaColors.primary : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'SAVE KHATA ENTRY',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (picked == null || !mounted) {
          return;
        }

        setState(() {
          _selectedDate = picked;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: KiranaColors.outlineVariant.withValues(
              alpha: 0.20,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: KiranaColors.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMM yyyy').format(_selectedDate),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: KiranaColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 19,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: KiranaColors.outlineVariant.withValues(
              alpha: 0.20,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: KiranaColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
