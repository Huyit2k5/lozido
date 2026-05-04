---
name: deepseek
description: Use this skill whenever a task involves displaying, formatting, or updating money, prices, costs, or financial values in the UI. Keywords: currency, money, price, format, utils, VND, cost, payment.
---

# 🚨 STRICT PROJECT STANDARD: CURRENCY FORMATTING

## Context
This project has a centralized, predefined utility for formatting all currency and money values. To maintain consistency across the app, **no custom currency formatting logic is allowed in UI files**.

## 🛑 What You MUST NOT Do (CRITICAL):
- **DO NOT** use string interpolation for money (e.g., `Text('${price} VND')`).
- **DO NOT** use Dart's native formatting directly in UI files (e.g., `price.toStringAsFixed(2)`).
- **DO NOT** import `intl` to use `NumberFormat` directly inside widgets.
- **DO NOT** write new helper functions for currency.

## ✅ What You MUST Do (Step-by-Step):
Whenever you are asked to display a price or money value:
1. **READ THE FILE:** You must first read the content of `lib/core/utils/format_currency.dart`.
2. **EXTRACT:** Identify the correct function or class method inside that file used for formatting (e.g., `formatCurrency()`, `AppFormat.money()`, etc.).
3. **IMPORT:** Import the `format_currency.dart` file into the target file you are modifying.
4. **APPLY:** Wrap the raw number/variable with the project's official formatting function.

## Example of Expected Behavior:

### ❌ BAD (Agent creates its own logic - REJECTED)
```dart
Text(
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(item.price),
  style: TextStyle(color: Colors.red),
)