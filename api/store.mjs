import {createHash} from 'node:crypto';
import { services,identify } from '../server/firebase.mjs';
import { StoreError,priceOrder,transitionOrder,validateProduct } from '../server/orders.mjs';
import {importStoreCatalog} from '../server/demo-catalog.mjs';
import {storeNotice} from '../server/notices.mjs';

export function createHandler(provideServices = services) {
return async function handler(req,res) {
  res.setHeader('Cache-Control','no-store');
  if (!['GET','POST','DELETE'].includes(req.method)) return res.status(405).json({error:'Method not allowed'});
  try {
    const {db,auth} = provideServices();
    const user = await identify(req,auth);
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body || {};
    if (JSON.stringify(body).length > 25000) throw new StoreError('Request too large',413);
    const action = req.query.action;
    const owner = db.collection('users').doc(user.uid);
    if (action === 'bootstrap' && req.method === 'POST') {
      if (!process.env.STORE_OWNER_EMAIL || user.email?.toLowerCase() !== process.env.STORE_OWNER_EMAIL.trim().toLowerCase() || user.email_verified !== true) throw new StoreError('Verified store owner required',403);
      await auth.setCustomUserClaims(user.uid,{admin:true});
      return res.status(200).json({admin:true});
    }
    if (action === 'receipt' && req.method === 'POST') {
      if (!/^[a-zA-Z0-9_-]{16,100}$/.test(body.requestId || '')) throw new StoreError('Invalid receipt');
      const receipt = await owner.collection('orders').doc(body.requestId).get();
      return res.status(200).json({found:receipt.exists});
    }
    if (['checkout','quote'].includes(action) && req.method === 'POST') {
      if ((action==='checkout' && !/^[a-zA-Z0-9_-]{16,100}$/.test(body.requestId || '')) || typeof body.addressId !== 'string' || !body.addressId || body.addressId.includes('/')) throw new StoreError('Invalid checkout request');
      const ref = owner.collection('orders').doc(action==='quote'?'quote':body.requestId);
      const result = await db.runTransaction(async tx => {
        if(action==='checkout') {
          const existing = await tx.get(ref);
          if (existing.exists) return existing.data();
        }
        const profile = await tx.get(owner);
        if (!profile.exists || profile.data().deleting) throw new StoreError('Account unavailable',409);
        const address = await tx.get(owner.collection('locations').doc(body.addressId));
        if (!address.exists) throw new StoreError('Shipping address not found');
        const cart = await tx.get(owner.collection('cart').limit(101));
        const entries = cart.docs.map(d=>({...d.data(),id:d.id}));
        const ids = [...new Set(entries.map(i=>i.product?.id))];
        if (ids.some(id=>typeof id !== 'string' || !id || id.includes('/'))) throw new StoreError('Invalid cart');
        const refs = ids.map(id=>db.collection('products').doc(id));
        const catalog = refs.length ? await tx.getAll(...refs) : [];
        const order = priceOrder(entries,catalog.filter(d=>d.exists).map(d=>({...d.data(),id:d.id})),address.data());
        const intent = [user.uid,body.addressId,cart.docs.map(doc=>doc.createTime.toMillis()),order];
        const quoteId = createHash('sha256').update(JSON.stringify(intent)).digest('hex');
        if(action==='quote') {delete order.stockUsed;return {...order,quoteId};}
        if(body.requestId!==quoteId) throw new StoreError('Cart or address changed. Refresh checkout before placing your order.',409);
        if(body.expectedAmount!==order.totalAmount) throw new StoreError('Prices changed. Refresh checkout to review the current total.',409);
        for (const doc of catalog) tx.update(doc.ref,{stock:doc.data().stock-order.stockUsed[doc.id]});
        delete order.stockUsed;
        const record = {...order,id:ref.id,userId:user.uid,createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),shippingAddress:Object.values(order.address).filter(Boolean).join(', ')};
        tx.create(ref,record);
        for (const doc of cart.docs) tx.delete(doc.ref);
        return record;
      });
      if(action==='checkout') await storeNotice(db,user.uid,result.id,result.status);
      return res.status(200).json(result);
    }
    if (action === 'orders' && req.method === 'GET') {
      const admin = req.query.admin === 'true';
      if (admin && user.admin !== true) throw new StoreError('Administrator access required',403);
      const query = admin ? db.collectionGroup('orders') : owner.collection('orders');
      const snapshot = await query.orderBy('createdAt','desc').limit(100).get();
      return res.status(200).json({orders:snapshot.docs.map(d=>d.data())});
    }
    if (action === 'transition' && req.method === 'POST') {
      const uid = user.admin === true ? body.userId : user.uid;
      if (typeof uid !== 'string' || uid.includes('/') || !/^[\w-]{1,128}$/.test(body.orderId || '')) throw new StoreError('Invalid order');
      const ref = db.doc(`users/${uid}/orders/${body.orderId}`);
      await db.runTransaction(async tx => {
        const doc = await tx.get(ref);
        if (!doc.exists) throw new StoreError('Order not found',404);
        const order = doc.data();
        const next = transitionOrder(order.status,body.status,user.admin === true);
        if (next === 'cancelled') {
          const amounts = new Map();
          for (const item of order.items) amounts.set(item.product.id,(amounts.get(item.product.id)||0)+item.quantity);
          const docs = await tx.getAll(...[...amounts.keys()].map(id=>db.doc(`products/${id}`)));
          for (const p of docs) if (p.exists) tx.update(p.ref,{stock:p.data().stock+amounts.get(p.id)});
        }
        const updates = {status:next,updatedAt:new Date().toISOString()};
        if (user.admin === true && body.trackingUrl) {
          if (typeof body.trackingUrl !== 'string' || body.trackingUrl.length > 2048 || !/^https:\/\//.test(body.trackingUrl)) throw new StoreError('Invalid tracking URL');
          updates.trackingUrl = body.trackingUrl;
        }
        tx.update(ref,updates);
      });
      await storeNotice(db,uid,body.orderId,body.status);
      return res.status(200).json({ok:true});
    }
    if (['importCatalog','importDemoCatalog'].includes(action) && req.method === 'POST') {
      if (user.admin !== true) throw new StoreError('Administrator access required',403);
      return res.status(200).json(await importStoreCatalog(db));
    }
    if (action === 'product' && req.method === 'POST') {
      if (user.admin !== true) throw new StoreError('Administrator access required',403);
      if (body.id != null && (typeof body.id !== 'string' || !/^[\w-]{1,128}$/.test(body.id))) throw new StoreError('Invalid product ID');
      const data = validateProduct(body);
      const ref = body.id ? db.collection('products').doc(String(body.id)) : db.collection('products').doc();
      await ref.set({...data,id:ref.id,updatedAt:new Date().toISOString()},{merge:true});
      return res.status(200).json({id:ref.id});
    }
    if (action === 'account' && req.method === 'DELETE') {
      if (Date.now()/1000-user.auth_time > 300) throw new StoreError('Please sign in again before deleting your account',401);
      await db.runTransaction(async tx => {
        const open = await tx.get(owner.collection('orders').where('status','not-in',['cancelled','delivered','returned','closed','return_rejected']).limit(1));
        if (!open.empty) throw new StoreError('Complete or cancel your open orders before deleting your account.',409);
        tx.set(db.collection('accountDeletions').doc(user.uid),{createdAt:new Date().toISOString()});
        tx.set(owner,{deleting:true},{merge:true});
      });
      await db.recursiveDelete(owner);
      await auth.deleteUser(user.uid);
      return res.status(200).json({ok:true});
    }
    throw new StoreError('Unknown action',404);
  } catch (error) {
    const known = error instanceof StoreError;
    if (!known) console.error('Store request failed',error.code || error.name);
    return res.status(known ? error.status : 500).json({error:known ? error.message : 'Store request failed. Please retry.'});
  }
};
}
export default createHandler();
