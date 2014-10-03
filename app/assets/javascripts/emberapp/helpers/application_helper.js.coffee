Ember.Handlebars.helper 'format-date', (date) ->
  moment(date).format('YYYY-MM-DD HH:mm')

Ember.Handlebars.helper 'state-name', (state) ->
  switch state
    when 'submitting' then '已提交'
    when 'cancelled'  then '已撤销'
    when 'submitted'  then '受理中'
    when 'accepted'   then '充值成功'
    when 'rejected'   then '已驳回'
    when 'checked'    then '充值成功'
    when 'warning'    then '异常'

