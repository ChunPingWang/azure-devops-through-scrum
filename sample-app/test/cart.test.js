const test = require('node:test');
const assert = require('node:assert');
const { Cart } = require('../src/cart');

const apple = { sku: 'A001', name: '蘋果', price: 30 };

test('加入商品後總額正確', () => {
  const c = new Cart();
  c.add(apple, 2);
  assert.strictEqual(c.total, 60);
});

test('重複加入同商品時數量累加', () => {
  const c = new Cart();
  c.add(apple);
  c.add(apple);
  assert.strictEqual(c.items.get('A001').qty, 2);
});

test('數量不可為負數（Bug #13）', () => {
  const c = new Cart();
  c.add(apple);
  assert.throws(() => c.updateQty('A001', -1));
});

test('移除商品', () => {
  const c = new Cart();
  c.add(apple);
  c.remove('A001');
  assert.strictEqual(c.total, 0);
});
