using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace PM.Platform.Core.Domain.Audit
{
    internal interface IAuditableEntity
    {
        DataSetDateTime CreatedDate { get; set; }
        DataSetDateTime? UpdatedDate { get; set; }

        string CreatedByActor { get; set; }
        string? UpdatedByActor { get; set; }
    }
}
