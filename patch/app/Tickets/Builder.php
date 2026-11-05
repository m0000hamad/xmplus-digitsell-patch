<?php
namespace App\Tickets;

// Encoded controllers also issue query-builder updates, which bypass save().
final class Builder extends \Illuminate\Database\Eloquent\Builder
{
    public function update(array $values)
    {
        return $this->getModel()->getConnection()->transaction(function () use ($values) {
            $rows = (clone $this)->get(['id', 'rootid', 'main_id', 'status', 'userid']);
            foreach ($rows as $row) {
                if (isset($values['files'])) Lifecycle::validateAttachment((string) $values['files'], (int) $row->userid);
                if ((int) $row->rootid !== 0) Lifecycle::assertOpen((int) $row->main_id);
                elseif (isset($values['status']) && (int) $values['status'] !== 0) Lifecycle::assertOpen((int) $row->id);
            }
            return parent::update($values);
        });
    }
}
