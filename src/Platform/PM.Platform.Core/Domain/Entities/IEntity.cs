using System;
using System.Collections.Generic;
using System.Text;

namespace PM.Platform.Core.Domain.Entities
{
    public interface IEntity
    {
        Guid Id { get; set; }
    }
}
