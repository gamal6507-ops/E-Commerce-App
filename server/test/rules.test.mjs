import test,{before,after} from 'node:test';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment,assertSucceeds,assertFails} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,updateDoc,deleteDoc} from 'firebase/firestore';
const enabled=!!process.env.FIRESTORE_EMULATOR_HOST;
let env;
const profile={id:'alice',username:'Alice',email:'alice@example.com',createdAt:'2026-11-19T00:00:00Z',providerId:'password',photoUrl:''};
before(async()=>{if(enabled) env=await initializeTestEnvironment({projectId:'demo-verve-store',firestore:{rules:await readFile('firestore.rules','utf8')}});});
after(async()=>{if(env) await env.cleanup();});
test('rules deny unauthenticated reads and cross-user access',{skip:!enabled},async()=>{
 await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'users/alice'),profile));
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'users/alice')));
 await assertFails(getDoc(doc(env.authenticatedContext('bob',{email:'bob@example.com'}).firestore(),'users/alice')));
 await assertSucceeds(getDoc(doc(env.authenticatedContext('alice',{email:'alice@example.com'}).firestore(),'users/alice')));
});
test('profile schema rejects password, role injection and immutable field updates',{skip:!enabled},async()=>{
 const db=env.authenticatedContext('alice',{email:'alice@example.com'}).firestore();
 await assertFails(updateDoc(doc(db,'users/alice'),{password:'never-store-this'}));
 await assertFails(updateDoc(doc(db,'users/alice'),{admin:true}));
 await assertFails(updateDoc(doc(db,'users/alice'),{createdAt:'different'}));
 await assertFails(updateDoc(doc(db,'users/alice'),{username:5}));
 await assertSucceeds(updateDoc(doc(db,'users/alice'),{username:'Updated'}));
});
test('clients cannot create orders, store cards or change stock',{skip:!enabled},async()=>{
 const db=env.authenticatedContext('alice',{email:'alice@example.com'}).firestore();
 await assertFails(setDoc(doc(db,'users/alice/orders/fake'),{totalAmount:0,status:'confirmed'}));
 await assertFails(setDoc(doc(db,'users/alice/paymentCards/card'),{cardNumber:'4111111111111111',cvv:'123'}));
 await assertFails(setDoc(doc(db,'products/p1'),{stock:999}));
 await assertFails(deleteDoc(doc(db,'users/alice')));
});
test('account deletion tombstone blocks recreation and orphaned subcollections',{skip:!enabled},async()=>{
 await env.withSecurityRulesDisabled(async c=>setDoc(doc(c.firestore(),'accountDeletions/deleted'),{deleted:true}));
 const db=env.authenticatedContext('deleted',{email:'alice@example.com'}).firestore();
 await assertFails(setDoc(doc(db,'users/deleted'),{...profile,id:'deleted'}));
 await assertFails(setDoc(doc(db,'users/absent/locations/x'),{}));
});
