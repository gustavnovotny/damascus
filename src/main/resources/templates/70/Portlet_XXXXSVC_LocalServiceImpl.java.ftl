<#include "./license.ftl">
<#include "./valuables.ftl">
<#assign createPath = "${createPath_val}/${application.model}/${application.model}-service/src/main/java/${packagePath}/service/impl/${capFirstModel}LocalServiceImpl.java">

package ${application.packageName}.service.impl;

import com.liferay.asset.kernel.model.AssetEntry;
import com.liferay.asset.kernel.model.AssetLinkConstants;
import com.liferay.portal.kernel.comment.CommentManagerUtil;
import com.liferay.portal.kernel.dao.orm.QueryUtil;
import com.liferay.portal.kernel.exception.PortalException;
import com.liferay.portal.kernel.exception.SystemException;
import com.liferay.portal.kernel.json.JSONFactoryUtil;
import com.liferay.portal.kernel.json.JSONObject;
import com.liferay.portal.kernel.model.ModelHintsUtil;
import com.liferay.portal.kernel.model.ResourceConstants;
import com.liferay.portal.kernel.model.SystemEventConstants;
import com.liferay.portal.kernel.model.User;
import com.liferay.portal.kernel.repository.model.ModelValidator;
import com.liferay.portal.kernel.search.Indexable;
import com.liferay.portal.kernel.search.IndexableType;
import com.liferay.portal.kernel.service.ServiceContext;
import com.liferay.portal.kernel.service.permission.ModelPermissions;
<#if generateActivity>
import com.liferay.portal.kernel.social.SocialActivityManagerUtil;
</#if>
import com.liferay.portal.kernel.systemevent.SystemEvent;
import com.liferay.portal.kernel.theme.ThemeDisplay;
import com.liferay.portal.kernel.util.Constants;
import com.liferay.portal.kernel.util.ContentTypes;
import com.liferay.portal.kernel.util.FriendlyURLNormalizerUtil;
import com.liferay.portal.kernel.util.HtmlUtil;
import com.liferay.portal.kernel.util.OrderByComparator;
import com.liferay.portal.kernel.util.ParamUtil;
import com.liferay.portal.kernel.util.StringPool;
import com.liferay.portal.kernel.util.StringUtil;
import com.liferay.portal.kernel.util.Validator;
import com.liferay.portal.kernel.util.WebKeys;
import com.liferay.portal.kernel.workflow.WorkflowConstants;
import com.liferay.portal.kernel.workflow.WorkflowHandlerRegistryUtil;
<#if generateActivity>
import com.liferay.social.kernel.model.SocialActivityConstants;
</#if>
import ${application.packageName}.exception.${capFirstModel}ValidateException;
import ${application.packageName}.model.${capFirstModel};
import ${application.packageName}.service.base.${capFirstModel}LocalServiceBaseImpl;
import ${application.packageName}.service.util.${capFirstModel}Validator;
<#if generateActivity>
import ${application.packageName}.social.${capFirstModel}ActivityKeys;
</#if>
import com.liferay.trash.kernel.exception.RestoreEntryException;
import com.liferay.trash.kernel.exception.TrashEntryException;
import com.liferay.trash.kernel.model.TrashEntry;

import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Pattern;

import javax.portlet.PortletException;
import javax.portlet.PortletRequest;

/**
 * ${capFirstModel}LocalServiceImpl
 *
 * @author Yasuyuki Takeo
 * @author ${damascus_author}
 */
public class ${capFirstModel}LocalServiceImpl
    extends ${capFirstModel}LocalServiceBaseImpl {

    @Override
    public void addEntryResources(
        long entryId, boolean addGroupPermissions, boolean addGuestPermissions)
        throws PortalException {

        ${capFirstModel} entry = ${uncapFirstModel}Persistence.findByPrimaryKey(entryId);

        addEntryResources(entry, addGroupPermissions, addGuestPermissions);
    }

    @Override
    public void addEntryResources(
        long entryId, String[] groupPermissions, String[] guestPermissions)
        throws PortalException {

        ${capFirstModel} entry = ${uncapFirstModel}Persistence.findByPrimaryKey(entryId);

        addEntryResources(entry, groupPermissions, guestPermissions);
    }

    @Override
    public void addEntryResources(
        ${capFirstModel} entry, boolean addGroupPermissions,
        boolean addGuestPermissions) throws PortalException {

        resourceLocalService.addResources(entry.getCompanyId(),
                                          entry.getGroupId(), entry.getUserId(), ${capFirstModel}.class.getName(),
                                          entry.getPrimaryKey(), false, addGroupPermissions,
                                          addGuestPermissions);
    }

    @Override
    public void addEntryResources(
        ${capFirstModel} entry, ModelPermissions modelPermissions)
        throws PortalException {

        resourceLocalService.addModelResources(entry.getCompanyId(),
                                               entry.getGroupId(), entry.getUserId(), ${capFirstModel}.class.getName(),
                                               entry.getPrimaryKey(), modelPermissions);
    }

    @Override
    public void addEntryResources(
        ${capFirstModel} entry, String[] groupPermissions, String[] guestPermissions)
        throws PortalException {

        resourceLocalService.addModelResources(entry.getCompanyId(),
                                               entry.getGroupId(), entry.getUserId(), ${capFirstModel}.class.getName(),
                                               entry.getPrimaryKey(), groupPermissions, guestPermissions);
    }

    /**
     * Add Entry
     *
     * @param orgEntry ${capFirstModel} model
     * @param serviceContext ServiceContext
     * @exception PortalException
     * @exception ${capFirstModel}ValidateException
     * @return created ${capFirstModel} model.
     */
    @Indexable(type = IndexableType.REINDEX)
    @Override
    public ${capFirstModel} addEntry(${capFirstModel} orgEntry, ServiceContext serviceContext)
        throws PortalException, ${capFirstModel}ValidateException {

        long userId = serviceContext.getUserId();

        //Validation

        ModelValidator<${capFirstModel}> modelValidator = new ${capFirstModel}Validator();
        modelValidator.validate(orgEntry);

        ${capFirstModel} entry = _addEntry(orgEntry, serviceContext);

        // Resources

        if (serviceContext.isAddGroupPermissions()
            || serviceContext.isAddGuestPermissions()) {

            addEntryResources(entry, serviceContext.isAddGroupPermissions(),
                              serviceContext.isAddGuestPermissions());
        } else {
            addEntryResources(entry, serviceContext.getModelPermissions());
        }

        // Asset

        updateAsset(userId, entry, serviceContext.getAssetCategoryIds(),
                    serviceContext.getAssetTagNames(),
                    serviceContext.getAssetLinkEntryIds(),
                    serviceContext.getAssetPriority());

        // Workflow

        return startWorkflowInstance(userId, entry, serviceContext);
    }

    /**
     * Start workflow
     *
     * @param userId User id of this model's owner
     * @param entry model object
     * @param serviceContext ServiceContext
     * @return model with workflow configrations.
     * @throws PortalException
     */
    protected ${capFirstModel} startWorkflowInstance(
        long userId, ${capFirstModel} entry, ServiceContext serviceContext)
        throws PortalException {

        Map<String, Serializable> workflowContext = new HashMap<String, Serializable>();

        String userPortraitURL = StringPool.BLANK;
        String userURL = StringPool.BLANK;

        if (serviceContext.getThemeDisplay() != null) {
            User user = userPersistence.findByPrimaryKey(userId);

            userPortraitURL = user
                .getPortraitURL(serviceContext.getThemeDisplay());
            userURL = user.getDisplayURL(serviceContext.getThemeDisplay());
        }

        workflowContext.put(WorkflowConstants.CONTEXT_USER_PORTRAIT_URL,
                            userPortraitURL);
        workflowContext.put(WorkflowConstants.CONTEXT_USER_URL, userURL);

        return WorkflowHandlerRegistryUtil.startWorkflowInstance(
            entry.getCompanyId(), entry.getGroupId(), userId,
            ${capFirstModel}.class.getName(), entry.getPrimaryKey(), entry,
            serviceContext, workflowContext);
    }

    public int countAllInGroup(long groupId) {
        int count = ${uncapFirstModel}Persistence.countByG_S(groupId,
                                                   WorkflowConstants.STATUS_APPROVED);
        return count;
    }

    public int countAllInUser(long userId) {
        int count = ${uncapFirstModel}Persistence.countByU_S(userId,
                                                   WorkflowConstants.STATUS_APPROVED);
        return count;
    }

    public int countAllInUserAndGroup(long userId, long groupId) {
        int count = ${uncapFirstModel}Persistence.countByG_U_S(groupId, userId,
                                                     WorkflowConstants.STATUS_APPROVED);
        return count;
    }

    public ${capFirstModel} deleteEntry(long primaryKey) throws PortalException {
        ${capFirstModel} entry = get${capFirstModel}(primaryKey);
        return deleteEntry(entry);
    }

    /**
     * Delete entry
     *
     * @param entry ${capFirstModel}
     * @return ${capFirstModel} oject
     * @exception PortalException
     */
    @Indexable(type = IndexableType.DELETE)
    @Override
    @SystemEvent(type = SystemEventConstants.TYPE_DELETE)
    public ${capFirstModel} deleteEntry(${capFirstModel} entry) throws PortalException {

        // Entry

        ${uncapFirstModel}Persistence.remove(entry);

        // Resources

        resourceLocalService.deleteResource(entry.getCompanyId(),
                                            ${capFirstModel}.class.getName(), ResourceConstants.SCOPE_INDIVIDUAL,
                                            entry.getPrimaryKey());

        // Asset

        assetEntryLocalService.deleteEntry(${capFirstModel}.class.getName(),
                                           entry.getPrimaryKey());

        // Comment

        deleteDiscussion(entry);

        // Ratings

        ratingsStatsLocalService.deleteStats(${capFirstModel}.class.getName(),
                                             entry.getPrimaryKey());

        // Trash

        trashEntryLocalService.deleteEntry(${capFirstModel}.class.getName(),
                                           entry.getPrimaryKey());

        // Workflow

        workflowInstanceLinkLocalService.deleteWorkflowInstanceLinks(
            entry.getCompanyId(), entry.getGroupId(), ${capFirstModel}.class.getName(),
            entry.getPrimaryKey());

        return entry;
    }

    /**
     * Delete discussion (comments)
     *
     * @param entry
     * @throws PortalException
     */
    protected void deleteDiscussion(${capFirstModel} entry) throws PortalException {
        CommentManagerUtil.deleteDiscussion(${capFirstModel}.class.getName(),
                                            entry.getPrimaryKey());
    }

    public List<${capFirstModel}> findAllInGroup(long groupId) {
        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence
            .findByG_S(groupId, WorkflowConstants.STATUS_APPROVED);
        return list;
    }

    public List<${capFirstModel}> findAllInGroup(
        long groupId, int start, int end,
        OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence.findByG_S(
            groupId, WorkflowConstants.STATUS_APPROVED, start, end,
            orderByComparator);
        return list;
    }

    public List<${capFirstModel}> findAllInGroup(
        long groupId, OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) findAllInGroup(groupId,
                                                              QueryUtil.ALL_POS, QueryUtil.ALL_POS, orderByComparator);
        return list;
    }

    public List<${capFirstModel}> findAllInUser(long userId) {
        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence
            .findByU_S(userId, WorkflowConstants.STATUS_APPROVED);
        return list;
    }

    public List<${capFirstModel}> findAllInUser(
        long userId, int start, int end,
        OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence.findByU_S(
            userId, WorkflowConstants.STATUS_APPROVED, start, end,
            orderByComparator);
        return list;
    }

    public List<${capFirstModel}> findAllInUser(
        long userId, OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) findAllInUser(userId,
                                                             QueryUtil.ALL_POS, QueryUtil.ALL_POS, orderByComparator);
        return list;
    }

    public List<${capFirstModel}> findAllInUserAndGroup(long userId, long groupId) {
        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence
            .findByG_U_S(groupId, userId, WorkflowConstants.STATUS_APPROVED);
        return list;
    }

    public List<${capFirstModel}> findAllInUserAndGroup(
        long userId, long groupId, int start, int end,
        OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) ${uncapFirstModel}Persistence.findByG_U_S(
            groupId, userId, WorkflowConstants.STATUS_APPROVED, start, end,
            orderByComparator);
        return list;
    }

    public List<${capFirstModel}> findAllInUserAndGroup(
        long userId, long groupId,
        OrderByComparator<${capFirstModel}> orderByComparator) {

        List<${capFirstModel}> list = (List<${capFirstModel}>) findAllInUserAndGroup(groupId,
                                                                     userId, QueryUtil.ALL_POS, QueryUtil.ALL_POS, orderByComparator);
        return list;
    }

    /**
     * Get Company entries
     *
     * @param companyId Company Id
     * @param status Workflow status
     * @param start start index of entries
     * @param end end index of entries
     * @return
     * @throws SystemException
     */
    public List<${capFirstModel}> getCompanyEntries(
        long companyId, int status, int start, int end) {

        if (status == WorkflowConstants.STATUS_ANY) {
            return ${uncapFirstModel}Persistence.findByCompanyId(companyId, start, end);
        } else {
            return ${uncapFirstModel}Persistence.findByC_S(companyId, status, start, end);
        }
    }

    /**
     * Get Company entries
     *
     * @param companyId Company Id
     * @param status Workflow status
     * @param start start index of entries
     * @param end end index of entries
     * @param obc Comparator for the order
     * @return List of entries
     * @throws SystemException
     */
    public List<${capFirstModel}> getCompanyEntries(
        long companyId, int status, int start, int end,
        OrderByComparator<${capFirstModel}> obc) {

        if (status == WorkflowConstants.STATUS_ANY) {
            return ${uncapFirstModel}Persistence.findByCompanyId(companyId, start, end,
                                                       obc);
        } else {
            return ${uncapFirstModel}Persistence.findByC_S(companyId, status, start, end,
                                                 obc);
        }
    }

    /**
     * Get Company entries counts
     *
     * @param companyId
     * @param status
     * @return
     * @throws SystemException
     */
    public int getCompanyEntriesCount(long companyId, int status) {
        if (status == WorkflowConstants.STATUS_ANY) {
            return ${uncapFirstModel}Persistence.countByCompanyId(companyId);
        } else {
            return ${uncapFirstModel}Persistence.countByC_S(companyId, status);
        }
    }

    public ${capFirstModel} get${capFirstModel}ByUrlTitle(
        long groupId, String urlTitle, int status) throws PortalException {

        ${capFirstModel} entry = null;

        if (status == WorkflowConstants.STATUS_ANY) {
            entry = ${uncapFirstModel}Persistence.fetchByG_UT(groupId, urlTitle);
        } else {
            List<${capFirstModel}> results = ${uncapFirstModel}Persistence.findByG_UT_ST(groupId,
                                                                       urlTitle, status);

            if (results != null && results.size() > 0) {
                entry = results.get(0);
            }
        }

        return entry;
    }

    /**
     * Moves the entry to the recycle bin.
     *
<#if generateActivity>
     * Social activity counters for this entry get disabled.
     *
</#if> 
     * @param userId the primary key of the user moving the entry
     * @param entry the entry to be moved
     * @return the moved entry
     */
    @Indexable(type = IndexableType.REINDEX)
    @Override
    public ${capFirstModel} moveEntryToTrash(long userId, ${capFirstModel} entry)
        throws PortalException {

        // Entry
        if (entry.isInTrash()) {
            throw new TrashEntryException();
        }

        int oldStatus = entry.getStatus();

        if (oldStatus == WorkflowConstants.STATUS_PENDING) {
            entry.setStatus(WorkflowConstants.STATUS_DRAFT);

            ${uncapFirstModel}Persistence.update(entry);
        }

        entry = updateStatus(userId, entry.getPrimaryKey(),
                             WorkflowConstants.STATUS_IN_TRASH, new ServiceContext(),
                             new HashMap<String, Serializable>());

        // Social

        JSONObject extraDataJSONObject = JSONFactoryUtil.createJSONObject();

        extraDataJSONObject.put("title", entry.get${application.asset.assetTitleFieldName?cap_first}());
<#if generateActivity>
        SocialActivityManagerUtil.addActivity(userId, entry,
                                              SocialActivityConstants.TYPE_MOVE_TO_TRASH,
                                              extraDataJSONObject.toString(), 0);
</#if>

        // Workflow

        if (oldStatus == WorkflowConstants.STATUS_PENDING) {
            workflowInstanceLinkLocalService.deleteWorkflowInstanceLink(
                entry.getCompanyId(), entry.getGroupId(),
                ${capFirstModel}.class.getName(), entry.getPrimaryKey());
        }

        return entry;
    }

    public ${capFirstModel} moveEntryToTrash(long userId, long entryId)
        throws PortalException {

        ${capFirstModel} entry = ${uncapFirstModel}Persistence.findByPrimaryKey(entryId);

        return moveEntryToTrash(userId, entry);
    }

    /**
     * Restores the entry with the ID from the recycle bin. Social activity
     * counters for this entry get activated.
     *
     * @param userId the primary key of the user restoring the entry
     * @param entryId the primary key of the entry to be restored
     * @return the restored entry from the recycle bin
     */
    @Indexable(type = IndexableType.REINDEX)
    @Override
    public ${capFirstModel} restoreEntryFromTrash(long userId, long entryId)
        throws PortalException {

        // Entry

        ${capFirstModel} entry = ${uncapFirstModel}Persistence.findByPrimaryKey(entryId);

        if (!entry.isInTrash()) {
            throw new RestoreEntryException(
                RestoreEntryException.INVALID_STATUS);
        }

        TrashEntry trashEntry = trashEntryLocalService
            .getEntry(${capFirstModel}.class.getName(), entryId);

        updateStatus(userId, entryId, trashEntry.getStatus(),
                     new ServiceContext(), new HashMap<String, Serializable>());

<#if generateActivity>
        // Social

        JSONObject extraDataJSONObject = JSONFactoryUtil.createJSONObject();

        extraDataJSONObject.put("title", entry.get${application.asset.assetTitleFieldName?cap_first}());


        SocialActivityManagerUtil.addActivity(userId, entry,
                                              SocialActivityConstants.TYPE_RESTORE_FROM_TRASH,
                                              extraDataJSONObject.toString(), 0);
                                              
</#if>
        return entry;
    }

    @Override
    public void updateAsset(
        long userId, ${capFirstModel} entry, long[] assetCategoryIds,
        String[] assetTagNames, long[] assetLinkEntryIds, Double priority)
        throws PortalException {

        boolean visible = false;

        if (entry.isApproved()) {
            visible = true;
        }

        String summary = HtmlUtil.extractText(
            StringUtil.shorten(entry.get${application.asset.assetSummaryFieldName?cap_first}(), 500));

        AssetEntry assetEntry = assetEntryLocalService.updateEntry(userId,
                                                                   entry.getGroupId(), entry.getCreateDate(), entry.getModifiedDate(),
                                                                   ${capFirstModel}.class.getName(), entry.getPrimaryKey(), entry.getUuid(), 0,
                                                                   assetCategoryIds, assetTagNames, true, visible, null, null, null,
                                                                   null, ContentTypes.TEXT_HTML, entry.get${application.asset.assetTitleFieldName?cap_first}(), null,
                                                                   summary, null, null, 0, 0, priority);

        assetLinkLocalService.updateLinks(userId, assetEntry.getEntryId(),
                                          assetLinkEntryIds, AssetLinkConstants.TYPE_RELATED);
    }

    @Override
    public void updateEntryResources(
        ${capFirstModel} entry, String[] groupPermissions, String[] guestPermissions)
        throws PortalException {

        resourceLocalService.updateResources(entry.getCompanyId(),
                                             entry.getGroupId(), ${capFirstModel}.class.getName(), entry.getPrimaryKey(),
                                             groupPermissions, guestPermissions);
    }

    /**
     * Edit Entry
     *
     * @param orgEntry ${capFirstModel} model
     * @param serviceContext ServiceContext
     * @exception PortalException
     * @exception ${capFirstModel}ValidateException
     * @return updated ${capFirstModel} model.
     */
    @Indexable(type = IndexableType.REINDEX)
    @Override
    public ${capFirstModel} updateEntry(${capFirstModel} orgEntry, ServiceContext serviceContext)
        throws PortalException, ${capFirstModel}ValidateException {

        User user = userPersistence.findByPrimaryKey(orgEntry.getUserId());

        //Validation

        ModelValidator<${capFirstModel}> modelValidator = new ${capFirstModel}Validator();
        modelValidator.validate(orgEntry);

        // Update entry
        ${capFirstModel} entry = _updateEntry(orgEntry.getPrimaryKey(), orgEntry,
                                      serviceContext);

        if (entry.isPending() || entry.isDraft()) {
        } else {
            entry.setStatus(WorkflowConstants.STATUS_DRAFT);
        }

        ${capFirstModel} updatedEntry = ${uncapFirstModel}Persistence.update(entry);

        // Asset
        updateAsset(updatedEntry.getUserId(), updatedEntry,
                    serviceContext.getAssetCategoryIds(),
                    serviceContext.getAssetTagNames(),
                    serviceContext.getAssetLinkEntryIds(),
                    serviceContext.getAssetPriority());

        updatedEntry = startWorkflowInstance(user.getUserId(), updatedEntry,
                                             serviceContext);

        return updatedEntry;
    }

    @Indexable(type = IndexableType.REINDEX)
    public ${capFirstModel} updateStatus(
        long userId, long entryId, int status, ServiceContext serviceContext,
        Map<String, Serializable> workflowContext) throws PortalException {

        // Entry

        User user = userPersistence.findByPrimaryKey(userId);
        Date now = new Date();

        ${capFirstModel} entry = ${uncapFirstModel}Persistence.findByPrimaryKey(entryId);

        int oldStatus = entry.getStatus();

        entry.setModifiedDate(serviceContext.getModifiedDate(now));
        entry.setStatus(status);
        entry.setStatusByUserId(user.getUserId());
        entry.setStatusByUserName(user.getFullName());
        entry.setStatusDate(serviceContext.getModifiedDate(now));

        ${uncapFirstModel}Persistence.update(entry);

        AssetEntry assetEntry = assetEntryLocalService
            .fetchEntry(${capFirstModel}.class.getName(), entryId);

        if ((assetEntry == null) || (assetEntry.getPublishDate() == null)) {
            serviceContext.setCommand(Constants.ADD);
        }

        JSONObject extraDataJSONObject = JSONFactoryUtil.createJSONObject();

        extraDataJSONObject.put("title", entry.get${application.asset.assetTitleFieldName?cap_first}());

        if (status == WorkflowConstants.STATUS_APPROVED) {

            // Asset

            assetEntryLocalService.updateEntry(${capFirstModel}.class.getName(),
                                               entryId, entry.getModifiedDate(), null, true, true);

<#if generateActivity>
            // Social

            if ((oldStatus != WorkflowConstants.STATUS_IN_TRASH)
                && (oldStatus != WorkflowConstants.STATUS_SCHEDULED)) {

                if (serviceContext.isCommandUpdate()) {

                    SocialActivityManagerUtil.addActivity(user.getUserId(),
                                                          entry, ${capFirstModel}ActivityKeys.UPDATE_${uppercaseModel},
                                                          extraDataJSONObject.toString(), 0);
                } else {
                    SocialActivityManagerUtil.addUniqueActivity(
                        user.getUserId(), entry,
                        ${capFirstModel}ActivityKeys.ADD_${uppercaseModel},
                        extraDataJSONObject.toString(), 0);
                }
            }

</#if>
            // Trash

            if (oldStatus == WorkflowConstants.STATUS_IN_TRASH) {
                CommentManagerUtil.restoreDiscussionFromTrash(
                    ${capFirstModel}.class.getName(), entryId);

                trashEntryLocalService.deleteEntry(${capFirstModel}.class.getName(),
                                                   entryId);
            }

        } else {

            // Asset

            assetEntryLocalService.updateVisible(${capFirstModel}.class.getName(),
                                                 entryId, false);

<#if generateActivity>
            // Social

            if ((status == WorkflowConstants.STATUS_SCHEDULED)
                && (oldStatus != WorkflowConstants.STATUS_IN_TRASH)) {

                if (serviceContext.isCommandUpdate()) {

                    SocialActivityManagerUtil.addActivity(user.getUserId(),
                                                          entry, ${capFirstModel}ActivityKeys.UPDATE_${uppercaseModel},
                                                          extraDataJSONObject.toString(), 0);
                } else {
                    SocialActivityManagerUtil.addUniqueActivity(
                        user.getUserId(), entry,
                        ${capFirstModel}ActivityKeys.ADD_${uppercaseModel},
                        extraDataJSONObject.toString(), 0);
                }
            }

</#if>
            // Trash

            if (status == WorkflowConstants.STATUS_IN_TRASH) {
                CommentManagerUtil
                    .moveDiscussionToTrash(${capFirstModel}.class.getName(), entryId);

                trashEntryLocalService.addTrashEntry(userId, entry.getGroupId(),
                                                     ${capFirstModel}.class.getName(), entry.getPrimaryKey(),
                                                     entry.getUuid(), null, oldStatus, null, null);

            } else if (oldStatus == WorkflowConstants.STATUS_IN_TRASH) {
                CommentManagerUtil.restoreDiscussionFromTrash(
                    ${capFirstModel}.class.getName(), entryId);

                trashEntryLocalService.deleteEntry(${capFirstModel}.class.getName(),
                                                   entryId);
            }

        }

        return entry;
    }

    /**
     * Copy models at add entry
     *
     * To process storing a record into database, copy the model passed into a
     * new model object here.
     *
     * @param entry model object
     * @param serviceContext ServiceContext
     * @return
     * @throws PortalException
     */
    protected ${capFirstModel} _addEntry(${capFirstModel} entry, ServiceContext serviceContext)
        throws PortalException {

        long id = counterLocalService.increment(${capFirstModel}.class.getName());

        ${capFirstModel} newEntry = ${uncapFirstModel}Persistence
            .create(id);

        User user = userPersistence.findByPrimaryKey(entry.getUserId());

        Date now = new Date();
        newEntry.setCompanyId(entry.getCompanyId());
        newEntry.setGroupId(entry.getGroupId());
        newEntry.setUserId(user.getUserId());
        newEntry.setUserName(user.getFullName());
        newEntry.setCreateDate(now);
        newEntry.setModifiedDate(now);

        newEntry.setUuid(serviceContext.getUuid());
        newEntry.setUrlTitle(
            getUniqueUrlTitle(
            id,
            entry.getGroupId(),
            String.valueOf(newEntry.getPrimaryKey()),
            entry.get${application.asset.assetTitleFieldName?cap_first}(),
            null,
            serviceContext));

        newEntry.set${application.asset.assetTitleFieldName?cap_first}(entry.get${application.asset.assetTitleFieldName?cap_first}());
        newEntry.set${application.asset.assetSummaryFieldName?cap_first}(entry.get${application.asset.assetSummaryFieldName?cap_first}());

        <#-- ---------------- -->
        <#-- field loop start -->
        <#-- ---------------- -->
        <#list application.fields as field >
        <#-- Primary key is ommited here because the pk is already created in newEntry -->
            <#if field.primary?? && field.primary == false >
        newEntry.set${field.name?cap_first}(entry.get${field.name?cap_first}());
            </#if>
        </#list>
        <#-- ---------------- -->
        <#-- field loop ends  -->
        <#-- ---------------- -->

        return ${uncapFirstModel}Persistence.update(newEntry);
    }

    /**
     * Copy models at update entry
     *
     * To process storing a record into database, copy the model passed into a
     * new model object here.
     *
     * @param primaryKey Primary key
     * @param entry model object
     * @param serviceContext ServiceContext
     * @return updated entry
     * @throws PortalException
     */
    protected ${capFirstModel} _updateEntry(
        long primaryKey, ${capFirstModel} entry, ServiceContext serviceContext)
        throws PortalException {

        ${capFirstModel} updateEntry = fetch${capFirstModel}(primaryKey);

        User user = userPersistence.findByPrimaryKey(entry.getUserId());

        Date now = new Date();
        updateEntry.setCompanyId(entry.getCompanyId());
        updateEntry.setGroupId(entry.getGroupId());
        updateEntry.setUserId(user.getUserId());
        updateEntry.setUserName(user.getFullName());
        updateEntry.setCreateDate(entry.getCreateDate());
        updateEntry.setModifiedDate(now);

        updateEntry.setUuid(entry.getUuid());
        updateEntry.setUrlTitle(
            getUniqueUrlTitle(
            updateEntry.getPrimaryKey(),
            entry.getGroupId(),
            String.valueOf(updateEntry.getPrimaryKey()),
            entry.get${application.asset.assetTitleFieldName?cap_first}(),
            updateEntry.getUrlTitle(),
            serviceContext));

        updateEntry.set${application.asset.assetTitleFieldName?cap_first}(entry.get${application.asset.assetTitleFieldName?cap_first}());
        updateEntry.set${application.asset.assetSummaryFieldName?cap_first}(entry.get${application.asset.assetSummaryFieldName?cap_first}());

        <#-- ---------------- -->
        <#-- field loop start -->
        <#-- ---------------- -->
        <#list application.fields as field >
        updateEntry.set${field.name?cap_first}(entry.get${field.name?cap_first}());
        </#list>
        <#-- ---------------- -->
        <#-- field loop ends  -->
        <#-- ---------------- -->

        return updateEntry;
    }

    /**
     * Get Record
     *
     * @param primaryKey Primary key
     * @return ${capFirstModel} object
     * @throws PortletException
     */
    public ${capFirstModel} getNewObject(long primaryKey) {

        primaryKey = (primaryKey <= 0) ? 0 : counterLocalService.increment();
        return create${capFirstModel}(primaryKey);
    }

    /**
     * Generating URL Title for unique URL
     *
     * @param entryId primaryKey of the model
     * @param title title for the asset
     * @return URL title string
     */
    protected String getUrlTitle(long entryId, String title) {
        if (title == null) {
            return String.valueOf(entryId);
        }

        title = StringUtil.toLowerCase(title.trim());

        if (Validator.isNull(title) || Validator.isNumber(title)) {
            title = String.valueOf(entryId);
        } else {
            title = FriendlyURLNormalizerUtil.normalizeWithPeriodsAndSlashes(title);
        }

        return ModelHintsUtil.trimString(
                    ${capFirstModel}.class.getName(), "urlTitle", title);
    }

    /**
     * Get Unique UrlTitle
     *
     * @param id CounterLocalService's generated ID at a record creation
     * @param groupId Group ID
     * @param primaryKey Generated record's id. Usually it's a primary Key
     * @param title Title of the record. Usually asset's title.
     * @return Unique UrlTitle strings
     * @throws PortalException
     */
    protected String getUniqueUrlTitle(
        long id, long groupId, String primaryKey, String title)
        throws PortalException {

        String urlTitle = getUrlTitle(id, title);

        return getUniqueUrlTitle(groupId, primaryKey, urlTitle);
    }

    /**
     * Generating a unique URL for asset
     *
     * @param id CounterLocalService's generated ID at a record creation
     * @param groupId Group ID
     * @param primaryKey Generated record's id. Usually it's a primary Key
     * @param title Title of the record. Usually asset's title.
     * @param oldUrlTitle Old url title to be repleaced with title
     * @param serviceContext
     * @return Unique UrlTitle strings
     * @throws PortalException
     */
    protected String getUniqueUrlTitle(
        long id, long groupId, String primaryKey, String title,
        String oldUrlTitle, ServiceContext serviceContext)
        throws PortalException {

        String serviceContextUrlTitle = ParamUtil.getString(
        serviceContext, "urlTitle");

        String urlTitle = null;

        if (Validator.isNotNull(serviceContextUrlTitle)) {
            urlTitle = getUrlTitle(id, serviceContextUrlTitle);
        }
        else if (Validator.isNotNull(oldUrlTitle)) {
            return oldUrlTitle;
        }
        else {
            urlTitle = getUniqueUrlTitle(id, groupId, primaryKey, title);
        }

        ${capFirstModel} entry = get${capFirstModel}ByUrlTitle(
        groupId, urlTitle, WorkflowConstants.STATUS_ANY);
        if ((entry != null) &&
        !Objects.equals(entry.getPrimaryKey(), primaryKey)) {

            urlTitle = getUniqueUrlTitle(id, groupId, primaryKey, urlTitle);
        }

        return urlTitle;
    }

    /**
     * Returns the record's unique URL title.
     *
     * @param  groupId the primary key of the record's group
     * @param  primaryKey the primary key of the record
     * @param  urlTitle the record's accessible URL title
     * @return the record's unique URL title
     */
    public String getUniqueUrlTitle(
        long groupId, String primaryKey, String urlTitle)
        throws PortalException {

        for (int i = 1;; i++) {
            ${capFirstModel} entry = get${capFirstModel}ByUrlTitle(groupId, urlTitle, WorkflowConstants.STATUS_ANY);

            if ((entry == null) || primaryKey.equals(entry.getPrimaryKey())) {
                break;
            }
            else {
                String suffix = StringPool.DASH + i;

                String prefix = urlTitle;

                if (urlTitle.length() > suffix.length()) {
                    prefix = urlTitle.substring(
                    0, urlTitle.length() - suffix.length());
                }

                urlTitle = prefix + suffix;
            }
        }

        return urlTitle;
    }

    /**
     * Converte Date Time into Date()
     *
     * @param request PortletRequest
     * @param prefix Prefix of the parameter
     * @return Date object
     */
    public Date getDateTimeFromRequest(PortletRequest request, String prefix) {
        int Year = ParamUtil.getInteger(request, prefix + "Year");
        int Month = ParamUtil.getInteger(request, prefix + "Month") + 1;
        int Day = ParamUtil.getInteger(request, prefix + "Day");
        int Hour = ParamUtil.getInteger(request, prefix + "Hour");
        int Minute = ParamUtil.getInteger(request, prefix + "Minute");
        int AmPm = ParamUtil.getInteger(request, prefix + "AmPm");

        if (AmPm == Calendar.PM) {
            Hour += 12;
        }

        LocalDateTime ldt = LocalDateTime.of(Year, Month, Day, Hour, Minute, 0);
        return Date.from(ldt.atZone(ZoneId.systemDefault()).toInstant());
    }

    /**
     * Populate Model with values from a form
     *
     * @param request PortletRequest
     * @return ${capFirstModel} Object
     * @throws PortletException
     * @throws ${capFirstModel}ValidateException
     */
    public ${capFirstModel} get${capFirstModel}FromRequest(
        long primaryKey, PortletRequest request) throws PortletException, ${capFirstModel}ValidateException {
        ThemeDisplay themeDisplay = (ThemeDisplay) request
            .getAttribute(WebKeys.THEME_DISPLAY);

        // Create or fetch existing data
        ${capFirstModel} entry;
        if (primaryKey <= 0) {
            entry = getNewObject(primaryKey);
        } else {
            entry = fetch${capFirstModel}(primaryKey);
        }

        try {
            <#-- ---------------- -->
            <#-- field loop start -->
            <#-- ---------------- -->
            <#list application.fields as field >
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Long" >
                    <#if field.primary?? && field.primary == true >
        entry.set${field.name?cap_first}(primaryKey);
                    <#else>
        entry.set${field.name?cap_first}(ParamUtil.getLong(request, "${field.name}"));
                    </#if>
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Varchar" >
        entry.set${field.name?cap_first}(ParamUtil.getString(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Date" >
        entry.set${field.name?cap_first}(getDateTimeFromRequest(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.DateTime" >
        entry.set${field.name?cap_first}(getDateTimeFromRequest(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Boolean" >
        entry.set${field.name?cap_first}(ParamUtil.getBoolean(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.DocumentLibrary" >
        entry.set${field.name?cap_first}(ParamUtil.getString(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Double" >
        entry.set${field.name?cap_first}(ParamUtil.getDouble(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Integer" >
        entry.set${field.name?cap_first}(ParamUtil.getInteger(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.RichText" >
        entry.set${field.name?cap_first}(ParamUtil.getString(request, "${field.name}"));
                </#if>
                <#if field.type?string == "com.liferay.damascus.cli.json.fields.Text" >
        entry.set${field.name?cap_first}(ParamUtil.getString(request, "${field.name}"));
                </#if>
            </#list>
            <#-- ---------------- -->
            <#-- field loop ends  -->
            <#-- ---------------- -->

            entry.set${application.asset.assetTitleFieldName?cap_first}(
                ParamUtil.getString(request, "${application.asset.assetTitleFieldName}"));
            entry.set${application.asset.assetSummaryFieldName?cap_first}(
                ParamUtil.getString(request, "${application.asset.assetSummaryFieldName}"));

            entry.setCompanyId(themeDisplay.getCompanyId());
            entry.setGroupId(themeDisplay.getScopeGroupId());
            entry.setUserId(themeDisplay.getUserId());
        } catch (Throwable e) {
            List<String> error = new ArrayList<>();
            error.add("value-convert-error");
            throw new ${capFirstModel}ValidateException(error);
        }

        return entry;
    }

    /**
     * Populate Model with values from a form
     *
     * @param primaryKey primary key
     * @param request PortletRequest
     * @return ${capFirstModel} Object
     * @throws PortletException
     */
    public ${capFirstModel} getInitialized${capFirstModel}(
        long primaryKey, PortletRequest request) throws PortletException {
        ThemeDisplay themeDisplay = (ThemeDisplay) request
            .getAttribute(WebKeys.THEME_DISPLAY);

        // Create or fetch existing data
        ${capFirstModel} entry = getNewObject(primaryKey);

        <#-- ---------------- -->
        <#-- field loop start -->
        <#-- ---------------- -->
        <#list application.fields as field >
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Long" >
                <#if field.primary?? && field.primary == true >
                    entry.set${field.name?cap_first}(primaryKey);
                <#else>
                    entry.set${field.name?cap_first}(0);
                </#if>
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Varchar" >
                entry.set${field.name?cap_first}("");
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Date" >
                entry.set${field.name?cap_first}(new Date());
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.DateTime" >
                entry.set${field.name?cap_first}(new Date());
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Boolean" >
                entry.set${field.name?cap_first}(true);
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.DocumentLibrary" >
                entry.set${field.name?cap_first}("");
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Double" >
                entry.set${field.name?cap_first}(0.0);
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Integer" >
                entry.set${field.name?cap_first}(0);
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.RichText" >
                entry.set${field.name?cap_first}("");
            </#if>
            <#if field.type?string == "com.liferay.damascus.cli.json.fields.Text" >
                entry.set${field.name?cap_first}("");
            </#if>
        </#list>
        <#-- ---------------- -->
        <#-- field loop ends  -->
        <#-- ---------------- -->
        entry.set${application.asset.assetTitleFieldName?cap_first}("");
        entry.set${application.asset.assetSummaryFieldName?cap_first}("");

        entry.setCompanyId(themeDisplay.getCompanyId());
        entry.setGroupId(themeDisplay.getScopeGroupId());
        entry.setUserId(themeDisplay.getUserId());

        return entry;
    }

    private static Pattern _friendlyURLPattern = Pattern.compile("[^a-z0-9_-]");

}