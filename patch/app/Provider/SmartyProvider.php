<?php
namespace App\Provider;

use Smarty;
use App\Http\Models\Currency;
use App\Services\AuthService;
use App\Library\Localization\Localization;
use Illuminate\Database\Capsule\Manager as DB;

final class SmartyProvider
{
	public static function render()
    {
		$smarty 	= new Smarty(); 
		
		if(!isset($_SESSION['locale'])){
			$_SESSION['locale'] = $_ENV['language'];
		}	
		
		$currency = DB::table(Currency::getTableName())
			->where('currency', (new ConfigProvider)->get('default_currency'))->first();
		
        $smarty->settemplatedir(BASE_PATH . '/view/'); 
        $smarty->setcompiledir(BASE_PATH . '/storage/smarty/compile/'); 
        $smarty->setcachedir(BASE_PATH . '/storage/smarty/cache/'); 
		$smarty->error_reporting = error_reporting() & ~E_USER_DEPRECATED;
		
		$smarty->assign('_ENV', $_ENV);
		$smarty->assign('translate', new Localization);
		$smarty->assign('user', AuthService::getUser());
		$smarty->assign('Config', (new ConfigProvider)->get());
		$smarty->assign('helpers', (new \App\Helpers\Helpers));
		$smarty->assign('session', (new \SlimSession\Helper()));
		$smarty->assign('gmt', (new \App\Helpers\Helpers)->gmt());
		$smarty->assign('currency', $currency);

		// time plans have no controller of their own - the templates reach the
		// package model through this helper instead
		$smarty->assign('timeplan', new \App\Http\Models\Package);

		return $smarty;
    }	
}
