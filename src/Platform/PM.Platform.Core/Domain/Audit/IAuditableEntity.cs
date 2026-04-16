using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace PM.Platform.Core.Domain.Audit
{
    public interface IAuditableEntity
    {
        DateTime CreatedDate { get; set; }
        DateTime? UpdatedDate { get; set; }

        string CreatedByActor { get; set; }
        string? UpdatedByActor { get; set; }
    }
}
