import test from 'node:test';
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { createHandler } from '../../api/store.mjs';

test('admin manages catalog and fulfillment while customer reviews quotes and requests a return', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  const app = initializeApp({ projectId: 'demo-verve-store' }, 'fulfillment');
  const db = getFirestore(app);
  const uid = 'journey_customer';
  const owner = db.doc('users/' + uid);
  const handler = createHandler(() => ({
    db,
    auth: { async verifyIdToken(token) { return token === 'staff' ? { uid: 'staff', admin: true } : { uid }; } },
  }));
  async function request(action, body = {}, { token = 'customer', method = 'POST', query = {}, status = 200 } = {}) {
    const response = {
      setHeader() {},
      status(code) { this.code = code; return this; },
      json(data) { this.data = data; },
    };
    await handler({ method, body, query: { action, ...query }, headers: { authorization: 'Bearer ' + token } }, response);
    assert.equal(response.code, status, action + ': ' + JSON.stringify(response.data));
    return response.data;
  }
  const productId = 'fulfillment_product';
  try {
    await owner.set({ id: uid });
    await request('product', { id: productId, name: 'Notebook', description: '', category: 'Books', price: 1.12, stock: 2, active: true }, { token: 'staff' });
    const address = owner.collection('locations').doc('home');
    await address.set({ recipient: 'Test', phone: '01000000000', street: 'Street', building: '1', unit: '', city: 'Cairo', country: 'Egypt', postalCode: '' });
    await owner.collection('cart').doc('line').set({ product: { id: productId }, quantity: 1 });
    const oldQuote = await request('quote', { addressId: 'home' });
    await address.update({ building: '2' });
    await request('checkout', { addressId: 'home', requestId: oldQuote.quoteId, expectedAmount: oldQuote.totalAmount }, { status: 409 });
    const quote = await request('quote', { addressId: 'home' });
    assert.equal(quote.totalAmount, 11.12);
    const order = await request('checkout', { addressId: 'home', requestId: quote.quoteId, expectedAmount: quote.totalAmount });
    assert.equal(order.address.building, '2');
    assert.equal((await request('receipt', { requestId: order.id })).found, true);
    const staffOrders = await request('orders', {}, { method: 'GET', token: 'staff', query: { admin: 'true' } });
    assert.ok(staffOrders.orders.some(entry => entry.id === order.id));
    for (const status of ['confirmed', 'shipped', 'delivered', 'return_requested', 'return_approved', 'returned', 'closed']) {
      await request('transition', { orderId: order.id, userId: uid, status }, { token: status === 'return_requested' ? 'customer' : 'staff' });
    }
    assert.equal((await owner.collection('orders').doc(order.id).get()).data().status, 'closed');
    assert.ok((await owner.collection('notifications').get()).size > 0);
  } finally {
    await db.recursiveDelete(owner);
    await db.doc('products/' + productId).delete();
    await deleteApp(app);
  }
});
