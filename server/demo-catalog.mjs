import {StoreError, validateProduct} from './orders.mjs';

const source = 'https://dummyjson.com/products?limit=0&select=title,price,thumbnail,description,category,stock,rating';
const sizeCategories = new Set(['mens-shirts', 'mens-shoes', 'tops', 'womens-dresses', 'womens-shoes']);

function formatCategory(raw) {
  return String(raw || 'General')
    .split(/[-_\s]+/)
    .filter(Boolean)
    .map(part => part[0].toUpperCase() + part.slice(1))
    .join(' ');
}

export async function importStoreCatalog(db, fetchCatalog = fetch) {
  const response = await fetchCatalog(source, {signal: AbortSignal.timeout(15000)});
  if (!response.ok) throw new StoreError('Catalog API unavailable', 503);
  const {products} = await response.json();
  if (!Array.isArray(products) || !products.length || products.length > 500) throw new StoreError('Invalid catalog payload', 502);
  const records = products.map(item => {
    if (!Number.isSafeInteger(item.id) || item.id < 1 || typeof item.title !== 'string') throw new StoreError('Invalid catalog product', 502);
    const data = validateProduct({
      name: item.title,
      description: item.description || '',
      price: item.price,
      category: formatCategory(item.category),
      stock: Math.max(0, Math.trunc(Number(item.stock) || 0)),
      imgUrl: item.thumbnail,
      active: true,
      requiresSize: sizeCategories.has(item.category),
    });
    return {...data, id: 'catalog_' + item.id, source: 'DummyJSON', averageRate: Number(item.rating) || 0};
  });
  // Preserve merchant edits and existing inventory on retries.
  let created = 0;
  for (let offset = 0; offset < records.length; offset += 100) {
    const chunk = records.slice(offset, offset + 100);
    created += await db.runTransaction(async tx => {
      const refs = chunk.map(record => db.collection('products').doc(record.id));
      const snapshots = await tx.getAll(...refs);
      let chunkCreated = 0;
      for (const [i, doc] of snapshots.entries()) {
        if (!doc.exists) {
          tx.create(refs[i], chunk[i]);
          chunkCreated++;
        }
      }
      return chunkCreated;
    });
  }
  return {created, existing: records.length - created, total: records.length};
}

export const importDemoCatalog = importStoreCatalog;
