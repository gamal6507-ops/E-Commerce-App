import test from 'node:test';
import assert from 'node:assert/strict';
import { priceOrder, transitionOrder } from '../orders.mjs';

const address = {recipient:'Test User',phone:'+201234567890',street:'Test street',building:'5',unit:'2',city:'Cairo',country:'Egypt',postalCode:'12345'};
const product = {id:'p1',name:'Test',price:19.99,stock:5,active:true,requiresSize:false};
test('server prices catalog data and ignores client price', () => {
  const result = priceOrder([{id:'c1',product:{id:'p1',price:0},quantity:2,size:'S'}], [product], address);
  assert.equal(result.subtotal,39.98); assert.equal(result.totalAmount,49.98);
});
test('rejects unavailable inventory and invalid quantities', () => {
  for (const quantity of [0,-1,1.5,6,Infinity]) assert.throws(()=>priceOrder([{product:{id:'p1'},quantity}], [product],address));
});
test('duplicates aggregate against stock before reservation', () => {
  assert.throws(()=>priceOrder([{product:{id:'p1'},quantity:3},{product:{id:'p1'},quantity:3}], [product],address));
});
test('rejects incomplete shipping details', () => {
  assert.throws(()=>priceOrder([{product:{id:'p1'},quantity:1}], [product],{city:'Cairo',country:'Egypt'}));
});
test('owner cannot confirm shipment or refund', () => {
  assert.throws(()=>transitionOrder('pending','shipped',false));
  assert.throws(()=>transitionOrder('return_requested','refunded',false));
  assert.equal(transitionOrder('pending','cancelled',false),'cancelled');
  assert.equal(transitionOrder('delivered','return_requested',false),'return_requested');
});
test('admin follows fulfillment lifecycle', () => {
  assert.equal(transitionOrder('pending','confirmed',true),'confirmed');
  assert.equal(transitionOrder('confirmed','shipped',true),'shipped');
  assert.throws(()=>transitionOrder('cancelled','shipped',true));
});
test('clothing items require size while market items checkout together via cash on delivery', () => {
  const shirt = {...product, id:'shirt1', name:'Shirt', requiresSize:true};
  const apple = {...product, id:'apple1', name:'Apples', requiresSize:false};
  assert.throws(()=>priceOrder([{id:'l1', product:{id:'shirt1'}, quantity:1}], [shirt], address));
  const order = priceOrder(
    [{id:'l1', product:{id:'shirt1'}, quantity:1, size:'M'}, {id:'l2', product:{id:'apple1'}, quantity:1}],
    [shirt, apple],
    address,
  );
  assert.equal(order.status,'pending');
  assert.equal(order.paymentMethod,'cash_on_delivery');
  assert.equal(order.items[0].size,'M');
  assert.equal(order.items[1].size,'none');
});
