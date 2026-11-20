import {StoreError, validateProduct} from './orders.mjs';

const source = 'https://dummyjson.com/products?limit=24&select=title,price,thumbnail,description,category,stock,rating';

export async function importDemoCatalog(db, fetchCatalog = fetch) {
  const response = await fetchCatalog(source, {signal: AbortSignal.timeout(10000)});
  if (!response.ok) throw new StoreError('Sample catalog unavailable', 503);
  const {products} = await response.json();
  if (!Array.isArray(products) || !products.length || products.length > 24) throw new StoreError('Invalid sample catalog', 502);
  const records = products.map(item => {
    if (!Number.isSafeInteger(item.id) || item.id < 1 || typeof item.title !== 'string') throw new StoreError('Invalid sample product', 502);
    const data = validateProduct({
      name: item.title + ' · Demo / تجريبي',
      description: 'للتجربة فقط، بدون دفع أو توصيل. Demo item. No payment or delivery.\n' + item.description,
      price: item.price, category: item.category, stock: item.stock,
      imgUrl: item.thumbnail, active: true, requiresSize: false,
    });
    return {...data, id: 'demo_dummyjson_' + item.id, demo: true, source: 'DummyJSON', averageRate: Number(item.rating) || 0};
  });
  // Preserve merchant edits and existing inventory on retries.
  return db.runTransaction(async tx => {
    const refs = records.map(record => db.collection('products').doc(record.id));
    const snapshots = await tx.getAll(...refs);
    let created = 0;
    for (const [i, doc] of snapshots.entries()) {
      if (!doc.exists) {
        tx.create(refs[i], records[i]);
        created++;
      }
    }
    return {created, existing: records.length - created};
  });
}
