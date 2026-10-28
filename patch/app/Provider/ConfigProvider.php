<?php
namespace App\Provider;

use App\Http\Models\Settings;

class ConfigProvider
{
    private $config;

    public function __construct()
    {
        $data = [];
        foreach (Settings::get() as $item) $data[$item->name] = $item->value;
        $this->config = $data;
        require_once dirname(__DIR__) . '/Patch/SubscriptionProfiles.php';
        \SubscriptionProfiles::scope($data);
    }

    public function get($name = false)
    {
        return $name ? ($this->config[$name] ?? false) : $this->config;
    }

    public function set($name, $value)
    {
        $row = Settings::where('name', $name)->first();
        if ($row) Settings::where('name', $name)->update(['value' => $value]);
        else {
            $row = new Settings();
            $row->name = $name;
            $row->value = $value;
            $row->save();
        }
        $this->config[$name] = $value;
        return $value;
    }
}
