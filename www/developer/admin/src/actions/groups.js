import * as constants from './constants';
import jsonPlaceholder from '../apis/jsonPlaceholder';

const fetchGroups = () => async dispatch => {
   await jsonPlaceholder.get(process.env.REACT_APP_groups)
      .then( response => {
         dispatch({
            type: constants.GROUPS,
            payload: response.data
         });
         
      })
      .catch( error => {
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: error.response.statusText, sumary: error.response.status }
         });
      });   
   
};

const addGroup = group => async dispatch => {
   await jsonPlaceholder.post(process.env.REACT_APP_groups, group)
      .then( response => {
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: "Added", severiry: "info" }
         });
      })
      .catch( error => {
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: error.response.statusText, sumary: error.response.status }
         });
      });
};

const deleteGroup = (groups, id) => async dispatch => {
   await jsonPlaceholder.delete(process.env.REACT_APP_groups + '/' + id)
      .then( response => {
         // Remove the group from all grous that has the id that was just removed from the DB
         var subGroups = groups.filter( group => {
            return group.id !== id;
         });
         // Update the group set in the store to reflect the removed group
         dispatch({
            type: constants.GROUPS,
            payload: subGroups
         });         
         
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: "Deleted", severity: "info" }
         });
      })
      .catch( error => {
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: error.response.statusText, sumary: error.response.status }
         });
      });
};

const updateGroup = (groups, group) => async dispatch => {
   await jsonPlaceholder.put(process.env.REACT_APP_groups + '/' + group.id, group)
      .then( response => {
         // Edit the group in the array of groups
         let editedGroups = [];
         groups.forEach( current => {
            if ( current.id === group.id ){
               current = group;
            }
            editedGroups.push(current);
         });
         // Update the group set in the store to reflect the edited group
         dispatch({
            type: constants.GROUPS,
            payload: editedGroups
         });
         
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: "Updated", severity: "info" }
         });
      })
      .catch( error => {
         dispatch({
            type: constants.MESSAGE,
            payload: { detail: error.response.statusText, sumary: error.response.status }
         });
      });
};

const setGroup = group => async dispatch => {
   dispatch({
      type: constants.GROUP,
      payload: group
   });   
};

export { addGroup, deleteGroup, fetchGroups, updateGroup, setGroup };