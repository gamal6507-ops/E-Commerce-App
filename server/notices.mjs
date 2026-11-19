export async function storeNotice(db,uid,orderId,status) {
  try {
    await db.doc(`users/${uid}/notifications/${orderId}_${status}`).create({
      title:'Order update / تحديث الطلب',body:`#${orderId}: ${status}`,
      type:'order',isRead:false,createdAt:new Date().toISOString(),
      payload:JSON.stringify({route:'/profile',orderId}),
    });
  } catch(error) { if(error.code!==6)console.error('Order notice unavailable',error.code||error.name); }
}
