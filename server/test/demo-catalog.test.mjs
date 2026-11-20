import assert from 'node:assert/strict';
import test from 'node:test';
import {initializeApp, deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
import {importDemoCatalog} from '../demo-catalog.mjs';

test('catalog import preserves existing products and staff edits on retry', {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async () => {
  const app = initializeApp({projectId:'demo-verve-store'}, 'catalog-import');
  const db = getFirestore(app);
  const product = db.doc('products/demo_dummyjson_1001');
  const fixture = async () => Response.json({products:[{
    id:1001, title:'Notebook', price:12, description:'Sample', category:'books', stock:8,
    thumbnail:'https://example.com/item.jpg', rating:4.2,
  }]});
  try {
    assert.deepEqual(await importDemoCatalog(db,fixture), {created:1,existing:0});
    assert.equal((await product.get()).get('demo'),true);
    await product.update({active:false,stock:2});
    assert.deepEqual(await importDemoCatalog(db,fixture), {created:0,existing:1});
    assert.equal((await product.get()).get('active'),false);
    assert.equal((await product.get()).get('stock'),2);
  } finally {
    await product.delete();
    await deleteApp(app);
  }
});
