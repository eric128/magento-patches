#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0

SUPEE-10266-1.14.2.0 | EE_1.14.2.0 | v1 | 4fc362292b37afda1b5c94cef19c2ae85b21d803 | Tue Sep 5 18:05:37 2017 +0300 | 8a17d46f55189d9f223728aa7e6bbd2d2c329395..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CustomerSegment/controllers/Adminhtml/CustomersegmentController.php app/code/core/Enterprise/CustomerSegment/controllers/Adminhtml/CustomersegmentController.php
index 0304dc2..282dfdb 100644
--- app/code/core/Enterprise/CustomerSegment/controllers/Adminhtml/CustomersegmentController.php
+++ app/code/core/Enterprise/CustomerSegment/controllers/Adminhtml/CustomersegmentController.php
@@ -30,6 +30,17 @@
 class Enterprise_CustomerSegment_Adminhtml_CustomersegmentController extends Mage_Adminhtml_Controller_Action
 {
     /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
+    /**
      * Initialize proper segment model
      *
      * @param string $requestParam
diff --git app/code/core/Mage/Admin/Model/Session.php app/code/core/Mage/Admin/Model/Session.php
index 70e06f4..9e79201 100644
--- app/code/core/Mage/Admin/Model/Session.php
+++ app/code/core/Mage/Admin/Model/Session.php
@@ -76,6 +76,7 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
             $parameters['factory'] : Mage::getModel('core/factory');
 
         $this->init('admin');
+        $this->logoutIndirect();
     }
 
     /**
@@ -99,6 +100,21 @@ class Mage_Admin_Model_Session extends Mage_Core_Model_Session_Abstract
     }
 
     /**
+     * Logout user if was logged not from admin
+     */
+    protected function logoutIndirect()
+    {
+        $user = $this->getUser();
+        if ($user) {
+            $extraData = $user->getExtra();
+            if (isset($extraData['indirect_login']) && $this->getIndirectLogin()) {
+                $this->unsetData('user');
+                $this->setIndirectLogin(false);
+            }
+        }
+    }
+
+    /**
      * Try to login user in admin
      *
      * @param  string $username
diff --git app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
index 6b3bf4d..6f628a3 100644
--- app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
+++ app/code/core/Mage/Adminhtml/Block/Notification/Grid/Renderer/Notice.php
@@ -43,7 +43,7 @@ class Mage_Adminhtml_Block_Notification_Grid_Renderer_Notice
      */
     public function render(Varien_Object $row)
     {
-        return '<span class="grid-row-title">' . $row->getTitle() . '</span>'
-            . ($row->getDescription() ? '<br />' . $row->getDescription() : '');
+        return '<span class="grid-row-title">' . $this->escapeHtml($row->getTitle()) . '</span>'
+            . ($row->getDescription() ? '<br />' . $this->escapeHtml($row->getDescription()) : '');
     }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
index cebd088..11932e2 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Form/Container.php
@@ -108,7 +108,10 @@ class Mage_Adminhtml_Block_Widget_Form_Container extends Mage_Adminhtml_Block_Wi
 
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array($this->_objectId => $this->getRequest()->getParam($this->_objectId)));
+        return $this->getUrl('*/*/delete', array(
+            $this->_objectId => $this->getRequest()->getParam($this->_objectId),
+            Mage_Core_Model_Url::FORM_KEY => $this->getFormKey()
+        ));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Controller/Action.php app/code/core/Mage/Adminhtml/Controller/Action.php
index d630e35..e2f25409 100644
--- app/code/core/Mage/Adminhtml/Controller/Action.php
+++ app/code/core/Mage/Adminhtml/Controller/Action.php
@@ -51,6 +51,13 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
     protected $_publicActions = array();
 
     /**
+     *Array of actions which can't be processed without form key validation
+     *
+     * @var array
+     */
+    protected $_forcedFormKeyActions = array();
+
+    /**
      * Used module name in current adminhtml controller
      */
     protected $_usedModuleName = 'adminhtml';
@@ -162,7 +169,7 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         $_isValidSecretKey = true;
         $_keyErrorMsg = '';
         if (Mage::getSingleton('admin/session')->isLoggedIn()) {
-            if ($this->getRequest()->isPost()) {
+            if ($this->getRequest()->isPost() || $this->_checkIsForcedFormKeyAction()) {
                 $_isValidFormKey = $this->_validateFormKey();
                 $_keyErrorMsg = Mage::helper('adminhtml')->__('Invalid Form Key. Please refresh the page.');
             } elseif (Mage::getSingleton('adminhtml/url')->useSecretKey()) {
@@ -179,6 +186,9 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
                     'message' => $_keyErrorMsg
                 )));
             } else {
+                if ($_keyErrorMsg != ''){
+                    Mage::getSingleton('adminhtml/session')->addError($_keyErrorMsg);
+                }
                 $this->_redirect( Mage::getSingleton('admin/session')->getUser()->getStartupPageUrl() );
             }
             return $this;
@@ -397,4 +407,27 @@ class Mage_Adminhtml_Controller_Action extends Mage_Core_Controller_Varien_Actio
         $user = Mage::getSingleton('admin/session')->getUser();
         return $user->validateCurrentPassword($password);
     }
+
+    /**
+     * Check forced use form key for action
+     *
+     *  @return bool
+     */
+    protected function _checkIsForcedFormKeyAction()
+    {
+        return in_array($this->getRequest()->getActionName(), $this->_forcedFormKeyActions);
+    }
+
+    /**
+     * Set actions name for forced use form key
+     *
+     * @param array | string $actionNames - action names for forced use form key
+     */
+    protected function _setForcedFormKeyActions($actionNames)
+    {
+        $actionNames = (is_array($actionNames)) ? $actionNames: (array)$actionNames;
+        $actionNames = array_merge($this->_forcedFormKeyActions, $actionNames);
+        $actionNames = array_unique($actionNames);
+        $this->_forcedFormKeyActions = $actionNames;
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index b6df896..db6b80f 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -37,6 +37,7 @@
 class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
 {
     const XML_INVALID                             = 'invalidXml';
+    const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
     const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
 
     /**
@@ -75,6 +76,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
                     Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
                 self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
+                    'Invalid template path used in layout update.'
+                ),
             );
         }
         return $this;
@@ -109,6 +113,15 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
                 Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
         }
 
+        // if layout update declare custom templates then validate their paths
+        if ($templatePaths = $value->xpath('*//template | *//@template | //*[@method=\'setTemplate\']/*')) {
+            try {
+                $this->_validateTemplatePath($templatePaths);
+            } catch (Exception $e) {
+                $this->_error(self::INVALID_TEMPLATE_PATH);
+                return false;
+            }
+        }
         $this->_setValue($value);
 
         foreach ($this->_protectedExpressions as $key => $xpr) {
@@ -119,4 +132,19 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
         }
         return true;
     }
+
+    /**
+     * Validate template path for preventing access to the directory above
+     * If template path value has "../" @throws Exception
+     *
+     * @param $templatePaths | array
+     */
+    protected function _validateTemplatePath(array $templatePaths)
+    {
+        foreach ($templatePaths as $path) {
+            if (strpos($path, '../') !== false) {
+                throw new Exception();
+            }
+        }
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index 9a75c97..f93f2f8 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -33,6 +33,16 @@
  */
 class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 
     protected function _initCustomer($idFieldName = 'id')
     {
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
index ce31262f..ed72af7 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/QueueController.php
@@ -63,6 +63,10 @@ class Mage_Adminhtml_Newsletter_QueueController extends Mage_Adminhtml_Controlle
      */
     public function dropAction ()
     {
+        $request = $this->getRequest();
+        if ($request->getParam('text') && !$request->getPost('text')) {
+            $this->getResponse()->setRedirect($this->getUrl('*/newsletter_queue'));
+        }
         $this->loadLayout('newsletter_queue_preview');
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index 8e09548..47467e6 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -142,6 +142,10 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
      */
     public function dropAction ()
     {
+        $request = $this->getRequest();
+        if ($request->getParam('text') && !$request->getPost('text')) {
+             $this->getResponse()->setRedirect($this->getUrl('*/newsletter_template'));
+        }
         $this->loadLayout('newsletter_template_preview');
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index aa5f5f6..88742e8 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -267,14 +267,16 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
     public function addgroupAction()
     {
         $orderItemIds = $this->getRequest()->getParam('order_items', array());
+        $customerId   = $this->_getCustomerSession()->getCustomerId();
 
-        if (!is_array($orderItemIds) || !$this->_validateFormKey()) {
+        if (!is_array($orderItemIds) || !$this->_validateFormKey() || !$customerId) {
             $this->_goBack();
             return;
         }
 
         $itemsCollection = Mage::getModel('sales/order_item')
             ->getCollection()
+            ->addFilterByCustomerId($customerId)
             ->addIdFilter($orderItemIds)
             ->load();
         /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
@@ -684,4 +686,14 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         $this->getResponse()->setHeader('Content-type', 'application/json');
         $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
     }
+
+    /**
+     * Get customer session model
+     *
+     * @return Mage_Customer_Model_Session
+     */
+    protected function _getCustomerSession()
+    {
+        return Mage::getSingleton('customer/session');
+    }
 }
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index 7e7fe11..a485d9c 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -475,5 +475,4 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
         }
         return $this->_arrayHelper;
     }
-
 }
diff --git app/code/core/Mage/Core/Model/Email/Template/Abstract.php app/code/core/Mage/Core/Model/Email/Template/Abstract.php
index 358dcbc..38a48f4 100644
--- app/code/core/Mage/Core/Model/Email/Template/Abstract.php
+++ app/code/core/Mage/Core/Model/Email/Template/Abstract.php
@@ -251,8 +251,11 @@ abstract class Mage_Core_Model_Email_Template_Abstract extends Mage_Core_Model_T
                 '_theme' => $theme,
             )
         );
+        $filePath = realpath($filePath);
+        $positionSkinDirectory = strpos($filePath, Mage::getBaseDir('skin'));
+        $validator = new Zend_Validate_File_Extension('css');
 
-        if (is_readable($filePath)) {
+        if ($validator->isValid($filePath) && $positionSkinDirectory !== false && is_readable($filePath)) {
             return (string) file_get_contents($filePath);
         }
 
diff --git app/code/core/Mage/Core/Model/File/Validator/Image.php app/code/core/Mage/Core/Model/File/Validator/Image.php
index ffdaeb4..bf2d95d0 100644
--- app/code/core/Mage/Core/Model/File/Validator/Image.php
+++ app/code/core/Mage/Core/Model/File/Validator/Image.php
@@ -90,6 +90,13 @@ class Mage_Core_Model_File_Validator_Image
         list($imageWidth, $imageHeight, $fileType) = getimagesize($filePath);
         if ($fileType) {
             if ($this->isImageType($fileType)) {
+                /**
+                 * if 'general/reprocess_images/active' false then skip image reprocessing.
+                 * NOTE: If you turn off images reprocessing, then your upload images process may cause security risks.
+                 */
+                if (!Mage::getStoreConfigFlag('general/reprocess_images/active')) {
+                    return null;
+                }
                 //replace tmp image with re-sampled copy to exclude images with malicious data
                 $image = imagecreatefromstring(file_get_contents($filePath));
                 if ($image !== false) {
diff --git app/code/core/Mage/Core/Model/Session/Abstract/Varien.php app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
index 5198464..c9e242c 100644
--- app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
+++ app/code/core/Mage/Core/Model/Session/Abstract/Varien.php
@@ -135,19 +135,24 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         if (Mage::app()->getFrontController()->getRequest()->isSecure() && empty($cookieParams['secure'])) {
             // secure cookie check to prevent MITM attack
             $secureCookieName = $sessionName . '_cid';
-            if (isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])
-                && $_SESSION[self::SECURE_COOKIE_CHECK_KEY] !== md5($cookie->get($secureCookieName))
-            ) {
-                session_regenerate_id(false);
-                $sessionHosts = $this->getSessionHosts();
-                $currentCookieDomain = $cookie->getDomain();
-                foreach (array_keys($sessionHosts) as $host) {
-                    // Delete cookies with the same name for parent domains
-                    if (strpos($currentCookieDomain, $host) > 0) {
-                        $cookie->delete($this->getSessionName(), null, $host);
+            if (isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])) {
+                if ($_SESSION[self::SECURE_COOKIE_CHECK_KEY] !== md5($cookie->get($secureCookieName))) {
+                    session_regenerate_id(false);
+                    $sessionHosts = $this->getSessionHosts();
+                    $currentCookieDomain = $cookie->getDomain();
+                    foreach (array_keys($sessionHosts) as $host) {
+                        // Delete cookies with the same name for parent domains
+                        if (strpos($currentCookieDomain, $host) > 0) {
+                            $cookie->delete($this->getSessionName(), null, $host);
+                        }
                     }
+                    $_SESSION = array();
+                } else {
+                    /**
+                     * Renew secure cookie expiration time if secure id did not change
+                     */
+                    $cookie->renew($secureCookieName, null, null, null, true, null);
                 }
-                $_SESSION = array();
             }
             if (!isset($_SESSION[self::SECURE_COOKIE_CHECK_KEY])) {
                 $checkId = Mage::helper('core')->getRandomString(16);
@@ -157,8 +162,8 @@ class Mage_Core_Model_Session_Abstract_Varien extends Varien_Object
         }
 
         /**
-        * Renew cookie expiration time if session id did not change
-        */
+         * Renew cookie expiration time if session id did not change
+         */
         if ($cookie->get(session_name()) == $this->getSessionId()) {
             $cookie->renew(session_name());
         }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 5294ff8..42b5f71 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -459,6 +459,9 @@
                     </protected>
                 </public_files_valid_paths>
             </file>
+            <reprocess_images>
+                <active>1</active>
+            </reprocess_images>
         </general>
     </default>
     <stores>
diff --git app/code/core/Mage/Rss/Helper/Data.php app/code/core/Mage/Rss/Helper/Data.php
index 0b5e5dc..76bcf7f 100644
--- app/code/core/Mage/Rss/Helper/Data.php
+++ app/code/core/Mage/Rss/Helper/Data.php
@@ -39,14 +39,25 @@ class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
      */
     const XML_PATH_RSS_ACTIVE = 'rss/config/active';
 
+    /** @var Mage_Rss_Model_Session  */
+    private $_rssSession;
+
+    /** @var Mage_Admin_Model_Session  */
+    private $_adminSession;
+
+    public function __construct()
+    {
+        $this->_rssSession = Mage::getSingleton('rss/session');
+        $this->_adminSession = Mage::getSingleton('admin/session');;
+    }
+
     /**
      * Authenticate customer on frontend
      *
      */
     public function authFrontend()
     {
-        $session = Mage::getSingleton('rss/session');
-        if ($session->isCustomerLoggedIn()) {
+        if ($this->_rssSession->isCustomerLoggedIn()) {
             return;
         }
         list($username, $password) = $this->authValidate();
@@ -65,17 +76,24 @@ class Mage_Rss_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function authAdmin($path)
     {
-        $session = Mage::getSingleton('rss/session');
-        if ($session->isAdminLoggedIn()) {
-            return;
+        if (!$this->_rssSession->isAdminLoggedIn() || !$this->_adminSession->isLoggedIn()) {
+            list($username, $password) = $this->authValidate();
+            Mage::getSingleton('adminhtml/url')->setNoSecret(true);
+            $user = $this->_adminSession->login($username, $password);
+        } else {
+            $user = $this->_rssSession->getAdmin();
         }
-        list($username, $password) = $this->authValidate();
-        Mage::getSingleton('adminhtml/url')->setNoSecret(true);
-        $adminSession = Mage::getSingleton('admin/session');
-        $user = $adminSession->login($username, $password);
-        //$user = Mage::getModel('admin/user')->login($username, $password);
-        if ($user && $user->getId() && $user->getIsActive() == '1' && $adminSession->isAllowed($path)) {
-            $session->setAdmin($user);
+        if ($user && $user->getId() && $user->getIsActive() == '1' && $this->_adminSession->isAllowed($path)) {
+            $adminUserExtra = $user->getExtra();
+            if ($adminUserExtra && !is_array($adminUserExtra)) {
+                $adminUserExtra = Mage::helper('core/unserializeArray')->unserialize($user->getExtra());
+            }
+            if (!isset($adminUserExtra['indirect_login'])) {
+                $adminUserExtra = array_merge($adminUserExtra, array('indirect_login' => true));
+                $user->saveExtra($adminUserExtra);
+            }
+            $this->_adminSession->setIndirectLogin(true);
+            $this->_rssSession->setAdmin($user);
         } else {
             $this->authFailed();
         }
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
index a75ce33..a108b47 100755
--- app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Item/Collection.php
@@ -152,4 +152,20 @@ class Mage_Sales_Model_Resource_Order_Item_Collection extends Mage_Sales_Model_R
         $this->getSelect()->where($resultCondition);
         return $this;
     }
+
+    /**
+     * Filter by customerId
+     *
+     * @param int|array $customerId
+     * @return Mage_Sales_Model_Resource_Order_Item_Collection
+     */
+    public function addFilterByCustomerId($customerId)
+    {
+        $this->getSelect()->joinInner(
+            array('order' => $this->getTable('sales/order')),
+            'main_table.order_id = order.entity_id', array())
+            ->where('order.customer_id IN(?)', $customerId);
+
+        return $this;
+    }
 }
diff --git app/code/core/Zend/Serializer/Adapter/PhpCode.php app/code/core/Zend/Serializer/Adapter/PhpCode.php
new file mode 100644
index 0000000..4007762
--- /dev/null
+++ app/code/core/Zend/Serializer/Adapter/PhpCode.php
@@ -0,0 +1,72 @@
+<?php
+/**
+ * Zend Framework
+ *
+ * LICENSE
+ *
+ * This source file is subject to the new BSD license that is bundled
+ * with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://framework.zend.com/license/new-bsd
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@zend.com so we can send you a copy immediately.
+ *
+ * @category   Zend
+ * @package    Zend_Serializer
+ * @subpackage Adapter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ * @version    $Id$
+ */
+/** @see Zend_Serializer_Adapter_AdapterAbstract */
+#require_once 'Zend/Serializer/Adapter/AdapterAbstract.php';
+
+/**
+ * This class replaces default Zend_Serializer_Adapter_PhpCode because of problem described in MPERF-9450
+ * The only difference between current class and original one is overwritten implementation of unserialize method
+ *
+ * @category   Zend
+ * @package    Zend_Serializer
+ * @subpackage Adapter
+ * @copyright  Copyright (c) 2005-2015 Zend Technologies USA Inc. (http://www.zend.com)
+ * @license    http://framework.zend.com/license/new-bsd     New BSD License
+ */
+class Zend_Serializer_Adapter_PhpCode extends Zend_Serializer_Adapter_AdapterAbstract
+{
+    /**
+     * Serialize PHP using var_export
+     *
+     * @param  mixed $value
+     * @param  array $opts
+     * @return string
+     */
+    public function serialize($value, array $opts = array())
+    {
+        return var_export($value, true);
+    }
+
+    /**
+     * Deserialize PHP string
+     *
+     * Warning: this uses eval(), and should likely be avoided.
+     *
+     * @param  string $code
+     * @param  array $opts
+     * @return mixed
+     * @throws Zend_Serializer_Exception on eval error
+     */
+    public function unserialize($code, array $opts = array())
+    {
+        $ret = '';
+        if (is_array($opts)) {
+            $eval = @eval('$ret=' . $code . ';');
+            if ($eval === false) {
+                $lastErr = error_get_last();
+                #require_once 'Zend/Serializer/Exception.php';
+                throw new Zend_Serializer_Exception('eval failed: ' . $lastErr['message']);
+            }
+        }
+        return $ret;
+    }
+}
diff --git app/design/adminhtml/default/default/template/backup/dialogs.phtml app/design/adminhtml/default/default/template/backup/dialogs.phtml
index c1859d8..1fbbfb5 100644
--- app/design/adminhtml/default/default/template/backup/dialogs.phtml
+++ app/design/adminhtml/default/default/template/backup/dialogs.phtml
@@ -120,7 +120,11 @@
                     <table class="form-list" cellspacing="0">
                         <tr>
                             <td style="padding-right: 8px;"><label for="password" class="nobr"><?php echo $this->__('User Password')?> <span class="required">*</span></label></td>
-                            <td><input type="password" name="password" id="password" class="required-entry"></td>
+                            <td>
+                                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                                <input type="password" name="password" id="password" class="required-entry" autocomplete="new-password">
+                            </td>
                         </tr>
                         <tr>
                             <td>&nbsp;</td>
@@ -151,7 +155,11 @@
                             </tr>
                             <tr>
                                 <td class="label"><label for="ftp_pass"><?php echo $this->__('FTP Password')?> <span class="required">*</span></label></td>
-                                <td class="value"><input type="password" name="ftp_pass" id="ftp_pass"></td>
+                                <td class="value">
+                                    <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                    <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                                    <input type="password" name="ftp_pass" id="ftp_pass" autocomplete="new-pawwsord">
+                                </td>
                             </tr>
                             <tr>
                                 <td class="label"><label for="ftp_path"><?php echo $this->__('Magento root directory')?></label></td>
diff --git app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
index dc40bd0..b0f7a2f 100644
--- app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/edit/options/type/file.phtml
@@ -33,7 +33,7 @@ OptionTemplateFile = '<table class="border" cellpadding="0" cellspacing="0">'+
             '<th class="type-type">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Price Type')); ?> + '</th>' +
             <?php endif; ?>
             '<th class="type-sku">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('SKU')); ?> + '</th>' +
-            '<th class="type-title">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Allowed File Extensions')); ?> + '</th>'+
+            '<th class="type-title">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Allowed File Extensions')); ?> + ' <span class="required">*</span>' + '</th>'+
             '<th class="last">' + <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('Maximum Image Size')); ?> + '</th>' +
         '</tr>' +
         '<tr>' +
@@ -45,7 +45,7 @@ OptionTemplateFile = '<table class="border" cellpadding="0" cellspacing="0">'+
             '<input type="hidden" name="product[options][{{option_id}}][price_type]" id="product_option_{{option_id}}_price_type">' +
             <?php endif; ?>
             '<td><input type="text" class="input-text" name="product[options][{{option_id}}][sku]" value="{{sku}}"></td>' +
-            '<td><input class="input-text" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>' +
+            '<td><input class="input-text required-entry" type="text" name="product[options][{{option_id}}][file_extension]" value="{{file_extension}}"></td>' +
             '<td class="type-last last" nowrap><input class="input-text" type="text" name="product[options][{{option_id}}][image_size_x]" value="{{image_size_x}}">' +
                 <?php echo $this->helper('core')->jsonEncode(Mage::helper('catalog')->__('x')) ?> +
                 '<input class="input-text" type="text" name="product[options][{{option_id}}][image_size_y]" value="{{image_size_y}}">' +
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 90c7744..062ee5c 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -70,7 +70,7 @@ $createDateStore    = $this->getStoreCreateDate();
             </tr>
             <tr>
                 <td><strong><?php echo $this->__('Customer Group:') ?></strong></td>
-                <td><?php echo $this->getGroupName() ?></td>
+                <td><?php echo $this->escapeHtml($this->getGroupName()) ?></td>
             </tr>
         </table>
         <address class="box-right">
diff --git app/design/adminhtml/default/default/template/login.phtml app/design/adminhtml/default/default/template/login.phtml
index 1bbd116..d2e88c2 100644
--- app/design/adminhtml/default/default/template/login.phtml
+++ app/design/adminhtml/default/default/template/login.phtml
@@ -58,8 +58,8 @@
                         <input type="text" id="username" name="login[username]" value="" class="required-entry input-text" /></div>
                     <div class="input-box input-right"><label for="login"><?php echo Mage::helper('adminhtml')->__('Password:') ?></label><br />
                         <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
-                        <input type="text" class="input-text no-display" name="dummy" id="dummy" />
-                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" /></div>
+                        <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                        <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" autocomplete="new-password" /></div>
                     <?php echo $this->getChildHtml('form.additional.info'); ?>
                     <div class="clear"></div>
                     <div class="form-buttons">
diff --git app/design/adminhtml/default/default/template/notification/toolbar.phtml app/design/adminhtml/default/default/template/notification/toolbar.phtml
index 33cd40a..0653850 100644
--- app/design/adminhtml/default/default/template/notification/toolbar.phtml
+++ app/design/adminhtml/default/default/template/notification/toolbar.phtml
@@ -75,7 +75,7 @@
         <strong class="label">
     <?php endif; ?>
 
-    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->getLatestNotice() ?>
+    <?php echo $this->__('Latest Message:') ?></strong> <?php echo $this->escapeHtml($this->getLatestNotice()); ?>
     <?php if (!empty($latestNoticeUrl)): ?>
         <a href="<?php echo $latestNoticeUrl ?>" onclick="this.target='_blank';"><?php echo $this->__('Read details') ?></a>
     <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
index 3875662..290011b 100644
--- app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
+++ app/design/adminhtml/default/default/template/oauth/authorize/form/login-simple.phtml
@@ -58,8 +58,10 @@
                                 <label for="login">
                                     <em class="required">*</em>&nbsp;<?php echo $this->__('Password') ?>
                                 </label>
+                                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                                <input type="password" class="input-text no-display" name="dummy" id="dummy" />
                                 <input type="password" id="login" name="login[password]" class="required-entry input-text"
-                                       value=""/></div>
+                                       value="" autocomplete="new-password"/></div>
                             <div class="clear"></div>
                             <div class="form-buttons">
                                 <button type="submit" class="form-button"
diff --git app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
index 920463c..2c15f92 100644
--- app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
+++ app/design/adminhtml/default/default/template/oauth/authorize/form/login.phtml
@@ -46,7 +46,9 @@
                         <div class="input-box input-left"><label for="username"><?php echo $this->__('User Name:') ?></label><br/>
                             <input type="text" id="username" name="login[username]" value="" class="required-entry input-text" /></div>
                         <div class="input-box input-right"><label for="login"><?php echo $this->__('Password:') ?></label><br />
-                            <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" /></div>
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" id="login" name="login[password]" class="required-entry input-text" value="" autocomplete="new-password"/></div>
                         <div class="clear"></div>
                         <div class="form-buttons">
                             <button type="submit" class="form-button" title="<?php echo $this->quoteEscape($this->__('Login')) ?>" ><?php echo $this->__('Login') ?></button>
diff --git app/design/adminhtml/default/default/template/resetforgottenpassword.phtml app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
index c36a2b8..e140447 100644
--- app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
+++ app/design/adminhtml/default/default/template/resetforgottenpassword.phtml
@@ -53,12 +53,16 @@
                         <div class="input-box f-left">
                             <label for="password"><em class="required">*</em> <?php echo $this->__('New Password'); ?></label>
                             <br />
-                            <input type="password" class="input-text required-entry validate-admin-password" name="password" id="password" />
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" class="input-text required-entry validate-admin-password" name="password" id="password" autocomplete="new-password"/>
                         </div>
                         <div class="input-box f-right">
                             <label for="confirmation"><em class="required">*</em> <?php echo $this->__('Confirm New Password'); ?></label>
                             <br />
-                            <input type="password" class="input-text required-entry validate-cpassword" name="confirmation" id="confirmation" />
+                            <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                            <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+                            <input type="password" class="input-text required-entry validate-cpassword" name="confirmation" id="confirmation" autocomplete="new-password"/>
                         </div>
                         <div class="clear"></div>
                         <div class="form-buttons">
diff --git app/design/adminhtml/default/default/template/sales/order/view/history.phtml app/design/adminhtml/default/default/template/sales/order/view/history.phtml
index 87c4c9e..7a1319b 100644
--- app/design/adminhtml/default/default/template/sales/order/view/history.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/history.phtml
@@ -75,6 +75,6 @@
     <?php endforeach; ?>
     </ul>
     <script type="text/javascript">
-    if($('order_status'))$('order_status').update('<?php echo $this->getOrder()->getStatusLabel() ?>');
+        if ($('order_status')) $('order_status').update('<?php echo $this->jsQuoteEscape($this->getOrder()->getStatusLabel()) ?>');
     </script>
 </div>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index e2c21c8..d967495 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -130,7 +130,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
                 <?php if ($_groupName = $this->getCustomerGroupName()) : ?>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('sales')->__('Customer Group') ?></label></td>
-                    <td class="value"><strong><?php echo $_groupName ?></strong></td>
+                    <td class="value"><strong><?php echo $this->escapeHtml($_groupName) ?></strong></td>
                 </tr>
                 <?php endif; ?>
                 <?php foreach ($this->getCustomerAccountData() as $data):?>
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
index 3d73674..42f08fd 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/onepage/payment/scripts.phtml
@@ -35,7 +35,6 @@ function enablePaymentMethods(free) {
             if (elements[i].name == 'payment[method]'
                 || elements[i].name == 'payment[use_customer_balance]'
                 || elements[i].name == 'payment[use_reward_points]'
-                || elements[i].name == 'form_key'
             ) {
                 methodName = elements[i].value;
                 if ((free && methodName == 'free') || (!free && methodName != 'free')) {
diff --git app/design/frontend/rwd/enterprise/template/giftcardaccount/onepage/payment/scripts.phtml app/design/frontend/rwd/enterprise/template/giftcardaccount/onepage/payment/scripts.phtml
index d666e7f..6770725 100644
--- app/design/frontend/rwd/enterprise/template/giftcardaccount/onepage/payment/scripts.phtml
+++ app/design/frontend/rwd/enterprise/template/giftcardaccount/onepage/payment/scripts.phtml
@@ -35,7 +35,6 @@ function enablePaymentMethods(free) {
             if (elements[i].name == 'payment[method]'
                 || elements[i].name == 'payment[use_customer_balance]'
                 || elements[i].name == 'payment[use_reward_points]'
-                || elements[i].name == 'form_key'
             ) {
                 methodName = elements[i].value;
                 if ((free && methodName == 'free') || (!free && methodName != 'free')) {
diff --git app/design/install/default/default/template/install/create_admin.phtml app/design/install/default/default/template/install/create_admin.phtml
index a4a2113..3d0f7e9 100644
--- app/design/install/default/default/template/install/create_admin.phtml
+++ app/design/install/default/default/template/install/create_admin.phtml
@@ -66,11 +66,16 @@
         <li>
             <div class="input-box">
                 <label for="password"><?php echo $this->__('Password') ?> <span class="required">*</span></label><br/>
-                <input type="password" name="admin[new_password]" id="password" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>"  class="required-entry validate-admin-password input-text"/>
+                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
+                <input type="password" name="admin[new_password]" id="password" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>" class="required-entry validate-admin-password input-text" autocomplete="new-password"/>
             </div>
             <div class="input-box">
-                <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span class="required">*</span></label><br/>
-                <input type="password" name="admin[password_confirmation]" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password Confirmation')) ?>" id="confirmation" class="required-entry validate-cpassword input-text"/>
+                <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span
+                            class="required">*</span></label><br/>
+                <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+                <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
+                <input type="password" name="admin[password_confirmation]" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password Confirmation')) ?>" id="confirmation" class="required-entry validate-cpassword input-text" autocomplete="new-password"/>
             </div>
         </li>
     </ul>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index bc083c1..ebdcdd4 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -33,6 +33,7 @@
 "12 Hours","12 Hours"
 "12h AM/PM","12h AM/PM"
 "2 Hours","2 Hours"
+"Invalid template path used in layout update.","Invalid template path used in layout update."
 "24 Hours","24 Hours"
 "24h","24h"
 "2YTD","2YTD"
diff --git downloader/template/login.phtml downloader/template/login.phtml
index 3e1af0a..0b0418f 100755
--- downloader/template/login.phtml
+++ downloader/template/login.phtml
@@ -35,7 +35,9 @@
     <p><small>Please re-enter your Magento Adminstration Credentials.<br/>Only administrators with full permissions will be able to log in.</small></p>
     <table class="form-list">
         <tr><td class="label"><label for="username">Username:</label></td><td class="value"><input id="username" name="username" value=""/></td></tr>
-        <tr><td class="label"><label for="password">Password:</label></td><td class="value"><input type="password" id="password" name="password"/></td></tr>
+        <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
+        <input type="password" class="input-text no-display" name="dummy" id="dummy" />
+        <tr><td class="label"><label for="password">Password:</label></td><td class="value"><input type="password" id="password" name="password" autocomplete="new-password"/></td></tr>
         <tr><td></td>
             <td class="value"><button type="submit">Log In</button></td></tr>
         </table>