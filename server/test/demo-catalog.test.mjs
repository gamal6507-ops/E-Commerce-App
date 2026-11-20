import assert from 'node:assert/strict';
import test from 'node:test';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {importStoreCatalog} from '../demo-catalog.mjs';

test('catalog import sets clothing sizes, omits demo text and preserves edits on retry', {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
  const app = initializeApp({projectId:'demo-verve-store'}, 'catalog-import');
  const db = getFirestore(app);
  const market = db.doc('products/catalog_1001');
  const clothing = db.doc('products/catalog_1002');
  const fixture = async () => Response.json({products:[
    {
      id:1001, title:'Fresh Apples', price:12, description:'Organic fruit', category:'groceries', stock:8,
      thumbnail:'https://example.com/apple.jpg', rating:4.2,
    },
    {
      id:1002, title:'Cotton Shirt', price:35, description:'Classic fit shirt', category:'mens-shirts', stock:5,
      thumbnail:'https://example.com/shirt.jpg', rating:4.7,
    },
  ]});
  try {
    assert.deepEqual(await importStoreCatalog(db,fixture), {created:2,existing:0,total:2});
    const mSnap = await market.get();
    const cSnap = await clothing.get();
    assert.equal(mSnap.get('name'), 'Fresh Apples');
    assert.equal(mSnap.get('category'), 'Groceries');
    assert.equal(mSnap.get('requiresSize'), false);
    assert.equal(mSnap.get('demo'), undefined);
    assert.equal(cSnap.get('category'), 'Mens Shirts');
    assert.equal(cSnap.get('requiresSize'), true);
    await market.update({active:false,stock:2});
    assert.deepEqual(await importStoreCatalog(db,fixture), {created:0,existing:2,total:2});
    assert.equal((await market.get()).get('active'),false);
    assert.equal((await market.get()).get('stock'),2);
  } finally {
    await market.delete();
    await clothing.delete();
    await deleteApp(app);
  }
});
