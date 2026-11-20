export class StoreError extends Error {
  constructor(message, status = 400) { super(message); this.status = status; }
}
export function shippingAddress(data) {
  const result = {};
  for (const field of ['recipient','phone','street','building','unit','city','country','postalCode']) {
    const value = data?.[field];
    if (typeof value !== 'string' || value.trim().length > 150 || (!['unit','postalCode'].includes(field) && !value.trim())) throw new StoreError(`Invalid address: ${field}`);
    result[field] = value.trim();
  }
  if (!/^\+?[0-9 ()-]{7,25}$/.test(result.phone)) throw new StoreError('Invalid phone number');
  return result;
}
export function priceOrder(cart, products, address) {
  const delivery = shippingAddress(address);
  if (!Array.isArray(cart) || cart.length < 1 || cart.length > 100) throw new StoreError('Cart must contain 1–100 items');
  const used = new Map();
  let cents = 0;
  const items = cart.map(item => {
    const product = products.find(p => p.id === item.product?.id);
    if (!product || product.active !== true || !Number.isFinite(product.price) || product.price <= 0) throw new StoreError('Product unavailable',409);
    if (!Number.isInteger(item.quantity) || item.quantity < 1 || item.quantity > 100) throw new StoreError('Invalid quantity');
    if (product.requiresSize && !['S','M','L','XL'].includes(item.size)) throw new StoreError('Select a valid size');
    const count = (used.get(product.id) || 0) + item.quantity;
    if (!Number.isInteger(product.stock) || product.stock < count) throw new StoreError('Insufficient stock',409);
    used.set(product.id,count);
    cents += Math.round(product.price * 100) * item.quantity;
    return {id:item.id,product:{id:product.id,name:product.name,imgUrl:product.imgUrl || '',price:product.price},quantity:item.quantity,size:product.requiresSize ? item.size : 'none'};
  });
  if (!Number.isSafeInteger(cents) || cents > 1_000_000_000) throw new StoreError('Order amount exceeds limit');
  return {items,subtotal:cents/100,shipping:10,totalAmount:(cents+1000)/100,address:delivery,paymentMethod:'cash_on_delivery',currency:'EGP',status:'pending',stockUsed:Object.fromEntries(used)};
}
export function transitionOrder(current,next,admin) {
  const owner = {pending:['cancelled'],confirmed:['cancellation_requested'],delivered:['return_requested']};
  const staff = {pending:['confirmed','cancelled'],confirmed:['shipped','cancelled'],cancellation_requested:['cancelled','confirmed'],shipped:['delivered'],delivered:['return_requested'],return_requested:['return_approved','return_rejected'],return_approved:['returned'],returned:['closed']};
  if (!(admin ? staff : owner)[current]?.includes(next)) throw new StoreError('Order transition not allowed',409);
  return next;
}
export function validateProduct(body) {
  if (!body || typeof body.name !== 'string' || !body.name.trim() || body.name.length > 200 || !Number.isFinite(body.price) || body.price <= 0 || body.price > 1_000_000 || !Number.isInteger(body.stock) || body.stock < 0 || body.stock > 1_000_000) throw new StoreError('Invalid product');
  if (body.imgUrl && (typeof body.imgUrl !== 'string' || body.imgUrl.length > 2048 || !body.imgUrl.startsWith('https://'))) throw new StoreError('Image must use HTTPS');
  if (typeof body.category !== 'string' || body.category.length > 100 || typeof body.description !== 'string' || body.description.length > 5000) throw new StoreError('Invalid product description');
  return {name:body.name.trim(),nameLower:body.name.trim().toLowerCase(),price:Math.round(body.price*100)/100,stock:body.stock,imgUrl:body.imgUrl || '',category:body.category,description:body.description,active:body.active === true,requiresSize:body.requiresSize === true,averageRate:0};
}
