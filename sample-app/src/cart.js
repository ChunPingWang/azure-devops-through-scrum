// ShopCart 購物車核心邏輯（Sprint 1 範圍：PBI #6 加入、#7 調整數量、#8 移除）
class Cart {
  constructor() {
    this.items = new Map(); // sku -> { sku, name, price, qty }
  }

  add({ sku, name, price }, qty = 1) {
    if (qty < 1) throw new Error('數量必須 >= 1');
    const existing = this.items.get(sku);
    if (existing) existing.qty += qty; // 已存在則累加（PBI #6 驗收條件 2）
    else this.items.set(sku, { sku, name, price, qty });
  }

  updateQty(sku, qty) {
    if (!Number.isInteger(qty) || qty < 1 || qty > 99) {
      throw new Error('數量範圍須為 1~99'); // PBI #7 / Bug #13
    }
    const item = this.items.get(sku);
    if (!item) throw new Error(`購物車中沒有 ${sku}`);
    item.qty = qty;
  }

  remove(sku) {
    return this.items.delete(sku);
  }

  get total() {
    let sum = 0;
    for (const { price, qty } of this.items.values()) sum += price * qty;
    return sum;
  }
}

module.exports = { Cart };
