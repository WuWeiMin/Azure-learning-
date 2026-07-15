// ============================================================
// 公式: OfflinePolicyProfile_SavePerformAction_WhenOnlineUpdateCase
// 触发: aia_offlinepolicyprofile 创建或更新时, 服务端同步
// 逻辑: 离线保单档案"转在线"时, 把数据同步回关联的Case
// ============================================================

on Create/Update of aia_offlinepolicyprofile {

    if ( statuscode == {Online}                              // A列: 状态原因 = Online
         && aia_referencepolicyprofileid 有值 )              // B列: 关联的正式保单档案已存在
    {
        执行 {UpdateCase};   // C列: Snippet,更新相关Case
                             // (具体更新哪个Case的哪些字段,要看Global Actions里UpdateCase的定义)
    }
    // 其他情况(状态非Online,或还没关联正式保单档案) → 什么都不做
}
