export const money = (value:number)=>`${new Intl.NumberFormat('ar-EG').format(value)} ج.م`
export const dateTime=(value:string)=>new Intl.DateTimeFormat('ar-EG',{dateStyle:'medium',timeStyle:'short'}).format(new Date(value))
