# Community Consensus System for Product Data

## Overview
Implements a **crowdsourced voting system** where users collectively verify and improve barcode product information. Similar to Wikipedia or Waze - the community determines what's correct.

## How It Works

### 1. User Flow

**First User (Initial Submission):**
```
Scan barcode → API returns "Unknown Product" 
→ User edits to "Rosarita Traditional Refried Beans"
→ Submits → Becomes initial consensus (100% confidence)
```

**Second User (Voting):**
```
Scan same barcode → Shows "Rosarita Traditional Refried Beans"
→ Sees "1 vote" badge
→ Can vote to confirm OR submit different version
→ Votes → Increases to "2 votes" (higher confidence)
```

**Third User (Alternative):**
```
Scan barcode → Sees current consensus
→ Thinks it's wrong → Submits "Rosarita Refried Beans (No Fat Added)"
→ Now 2 submissions exist with votes
→ Highest voted becomes consensus
```

### 2. Consensus Algorithm

**Confidence Score:**
```
confidence = (top_votes / total_votes) * 100
```

**Verification Criteria:**
- ✅ **Verified** when:
  - At least 5 votes on top submission
  - At least 70% confidence
  - At least 2 different users voted

**Example:**
```
Submission A: 8 votes
Submission B: 2 votes
Total: 10 votes

Confidence: (8/10) * 100 = 80%
Verified: Yes ✅ (8 votes, 80%, 2+ users)
```

### 3. Data Structure

**Firestore: `barcode_consensus/{barcode}`**
```json
{
  "barcode": "0044300106321",
  "consensus": {
    "name": "Rosarita Traditional Refried Beans",
    "brand": "Rosarita",
    "category": "Pantry",
    "image_url": "https://...",
    "votes": 8,
    "voters": ["user1", "user2", "user3", ...]
  },
  "submissions": [
    {
      "user_id": "user1",
      "name": "Rosarita Traditional Refried Beans",
      "brand": "Rosarita",
      "category": "Pantry",
      "image_url": "https://...",
      "votes": 8,
      "voters": ["user1", "user2", "user3", ...],
      "submitted_at": Timestamp
    },
    {
      "user_id": "user4",
      "name": "Rosarita Refried Beans",
      "brand": "Rosarita", 
      "category": "Pantry",
      "image_url": "https://...",
      "votes": 2,
      "voters": ["user4", "user5"],
      "submitted_at": Timestamp
    }
  ],
  "total_votes": 10,
  "total_scans": 156,
  "confidence_score": 80.0,
  "verified": true,
  "last_updated": Timestamp
}
```

## Integration Steps

### Step 1: Update Smart Barcode Service

Modify `smart_barcode_service.dart` to check consensus first:

```dart
import 'barcode_consensus_service.dart';

class SmartBarcodeService {
  static final BarcodeConsensusService _consensusService = BarcodeConsensusService();
  
  static Future<Map<String, dynamic>?> smartLookup(String barcode) async {
    // 1. Check community consensus FIRST
    final consensusData = await _consensusService.getConsensusData(barcode);
    if (consensusData != null) {
      await _consensusService.incrementScanCount(barcode);
      return consensusData;
    }
    
    // 2. Fall back to cache
    final cachedData = await _cacheService.getCachedBarcode(barcode);
    if (cachedData != null) {
      return cachedData;
    }
    
    // 3. Fall back to API
    // ... existing code
  }
}
```

### Step 2: Add Voting Button to Confirmation Dialog

In `smart_barcode_confirmation_dialog.dart`, add a "Vote" button:

```dart
import '../widgets/voting_dialog.dart';
import '../services/barcode_consensus_service.dart';

// In the build method, add after the header:
if (widget.productData['source'] == 'Community Consensus') ...[
  const SizedBox(height: 12),
  Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified, size: 18, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Community Verified',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                '${widget.productData['total_votes']} votes • ${widget.productData['confidence_score'].toStringAsFixed(0)}% confidence',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => VotingDialog(
                barcode: widget.barcode,
                currentData: widget.productData,
              ),
            );
          },
          icon: const Icon(Icons.how_to_vote, size: 16),
          label: const Text('Vote'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        ),
      ],
    ),
  ),
],
```

### Step 3: Submit to Consensus on Save

In `_confirmAndAddToInventory()`, after caching:

```dart
// ALWAYS cache user data
await _cacheService.cacheBarcode(...);

// ALSO submit to community consensus
final consensusService = BarcodeConsensusService();
await consensusService.submitProductData(
  widget.barcode,
  productDataToCache,
  imageFile: _uploadedImage,
);
```

## Features

### ✅ Implemented

1. **Consensus Calculation** - Automatic selection of most-voted submission
2. **Voting System** - Users can vote for existing submissions
3. **Submission System** - Users can add new product versions
4. **Confidence Scoring** - Percentage based on vote distribution
5. **Verification Status** - Auto-verified when criteria met
6. **Image Support** - Each submission can have its own image
7. **Vote Migration** - User's vote moves when they vote for different submission
8. **Scan Tracking** - Tracks popularity of products

### 🎯 Advanced Features (Optional)

#### User Reputation System
Track user contribution quality:

```dart
users/{userId}/consensus_stats: {
  submissions: 12,
  votes_received: 156,
  accuracy_score: 0.85, // How often their submissions become consensus
  reputation_level: "Trusted Contributor"
}
```

Weight votes by reputation:
- New users: 1x vote weight
- Trusted contributors: 2x vote weight
- Expert contributors: 3x vote weight

#### Reporting System
Allow users to report incorrect data:

```dart
reports/{reportId}: {
  barcode: "...",
  submission_index: 1,
  reason: "wrong_product",
  reporter_id: "...",
  status: "pending"
}
```

Auto-remove submissions with 5+ reports.

#### Time Decay
Older submissions lose vote weight over time:

```dart
effective_votes = votes * decay_factor
decay_factor = 1.0 - (age_in_days / 365) * 0.3
```

#### Change History
Track all consensus changes:

```dart
consensus_history/{barcode}/changes: [
  {
    from: "Unknown Product",
    to: "Rosarita Traditional Refried Beans",
    votes_before: 0,
    votes_after: 1,
    changed_at: Timestamp
  }
]
```

## UI Mockups

### Voting Dialog
```
┌─────────────────────────────────────┐
│ 🗳️  Vote for Correct Info          │
│    Help improve product data    ×   │
├─────────────────────────────────────┤
│ ℹ️  Vote for the most accurate     │
│    product information...           │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [img] Rosarita Traditional  ✓   │ │
│ │       Refried Beans             │ │
│ │       Rosarita • Pantry         │ │
│ │                          👍 8   │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [img] Rosarita Refried Beans    │ │
│ │       Rosarita • Pantry         │ │
│ │                          👍 2   │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Consensus Badge (on confirmation dialog)
```
┌─────────────────────────────────────┐
│ ✅ Community Verified               │
│    8 votes • 80% confidence  [Vote] │
└─────────────────────────────────────┘
```

## Security Rules

**Firestore Rules:**

```javascript
match /barcode_consensus/{barcode} {
  // Anyone can read
  allow read: if true;
  
  // Only authenticated users can write
  allow create: if request.auth != null;
  
  allow update: if request.auth != null && (
    // Can only add to submissions array
    request.resource.data.submissions.size() >= resource.data.submissions.size()
  );
}

match /consensus_images/{barcode}/{imageId} {
  // Anyone can read
  allow read: if true;
  
  // Only authenticated users can upload
  allow write: if request.auth != null;
}
```

## Testing Checklist

- [ ] First user submits data → becomes consensus
- [ ] Second user votes for existing → vote count increases
- [ ] User votes for submission A, then votes for B → vote moves
- [ ] Submission with most votes becomes consensus
- [ ] Confidence score calculates correctly
- [ ] Verification status updates when criteria met
- [ ] Scan count increments on each lookup
- [ ] Images upload correctly per submission
- [ ] Voting dialog displays all submissions sorted by votes
- [ ] User's current vote is highlighted
- [ ] Top-voted submission shows verified badge
- [ ] Consensus data prioritized over cache and API

## Analytics to Track

### Product Metrics
- Most scanned products
- Most voted products
- Products with highest confidence
- Products needing verification (< 70%)

### User Metrics
- Top contributors (most submissions)
- Top voters (most votes cast)
- User accuracy (submission → consensus rate)

### System Health
- Average confidence score
- Verification rate (% of products verified)
- Consensus stability (how often it changes)
- Time to verification (scans until verified)

## Gamification Ideas

### Badges
- 🥇 "First Contributor" - First to submit data for a product
- ✅ "Verifier" - Voted on 10 products
- 🏆 "Trusted Source" - 5 submissions became consensus
- 🌟 "Expert" - 100+ votes received on submissions

### Leaderboard
Show top contributors in app:
```
Top Contributors This Month
1. @user123 - 45 submissions, 234 votes
2. @user456 - 32 submissions, 187 votes
3. @user789 - 28 submissions, 156 votes
```

---

## Quick Start

1. **Install service files** (already created)
   - `lib/services/barcode_consensus_service.dart`
   - `lib/widgets/voting_dialog.dart`

2. **Update smart_barcode_service.dart** to check consensus first

3. **Add voting button** to confirmation dialog

4. **Submit to consensus** when user saves

5. **Deploy Firestore rules** for security

6. **Test with multiple users** to verify voting works

## Benefits

✅ **For Users:**
- More accurate product data
- Community-driven quality
- Transparency (see all submissions)
- Gamification/contribution rewards

✅ **For You:**
- Better data quality over time
- User engagement increases
- Reduces support burden
- Community moderates itself
- Free data improvement

✅ **For The Ecosystem:**
- Shared knowledge base
- Network effects (more users = better data)
- Self-improving system
- Crowd wisdom > single source
