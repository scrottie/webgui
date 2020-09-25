import React, {useContext} from 'react';
import {Checkbox} from 'primereact/checkbox';
import LanguageRendererField from '../../languageRenderer';
import RadioField from '../radioRenderer';
import FieldContext from '../../../contexts/fields';

import './Contact.css';
export default ({user, updateField}) => {
   const context = useContext(FieldContext);
   
   return (
      <div>
         <LanguageRendererField object={user} fieldName="language" fieldLabel="Language:" updateFieldState={updateField} />
         <div className={context.parent}>
            <div className={context.label}>Are you available to be added as a Friend?:</div>
            <Checkbox className={context.value} checked={user.friendly} onChange={e => updateField("friendly", e.checked)} />
         </div>
         <div className={context.parent}>         
            <div className={context.label}>Date Format:</div>
            <div className={context.value}>{user.dateformat}</div>
         </div>
         <div className={context.parent}>         
            <div className={context.label}>Time Format:</div>
            <div className={context.value}>{user.timeformat}</div>
         </div>
         <RadioField fieldName="profileprivacy" fieldLabel="Profile Privacy:" fieldValue={user.profileprivacy} 
            updateFieldState={updateField} context={context} />
         <RadioField fieldName="messageoptions" fieldLabel="Private Message Options:" fieldValue={user.messageoptions} 
            updateFieldState={updateField} context={context} />
         <div className={context.parent}>            
            <div className={context.label}>Show when online?:</div>
            <Checkbox className={context.value} checked={user.showwhenonline} onChange={e => updateField("showwhenonline", e.checked)} />
         </div>
         <div className={context.parent}>            
            <div className={context.label}>Receive inbox notifications as email?:</div>
            <Checkbox className={context.value} checked={user.notifyemail} onChange={e => updateField("notifyemail", e.checked)} />
         </div>
         <div className={context.parent}>            
            <div className={context.label}>Receive inbox notifications as SMS?:</div>
            <Checkbox className={context.value} checked={user.notifysms} onChange={e => updateField("notifysms", e.checked)} /> 
         </div>
      </div>
   );
   
};