<?php

namespace Dockworker\Robo\Plugin\Commands;

use Dockworker\DockworkerDaemonCommands;

/**
 * Provides commands for building and deploying the DSpace Backend application.
 */
class DSpaceBackendDeploymentCommands extends DockworkerDaemonCommands
{
    /**
     * Provides error log triggers and exceptions for the DSpace Backend application.
     *
     * @hook on-event dockworker-logs-errors-exceptions
     *
     * @return mixed[]
     *   The error log exceptions.
     */
    public function provideErrorLogConfiguration(): array
    {
        return [
            [],
            array_values(
                [
                    'Lines that also have INFO aren\'t errors' => 'INFO',
                    'Solr statistics module not enabled' => 'configuration is missing in solr-statistics',
                    'Concurrent transaction notice, not critical' => 'here is already a transaction in progress',
                    'Known non-critical ORCID factory error' => 'ERROR unknown unknown org.dspace.orcid.model.factory.OrcidFactoryUtils',
                    'Known non-critical ORCID token error (legacy phrasing)' => 'Cannot retrieve ORCID access token',
                    'Known non-critical ORCID token error (DSpace 9.x phrasing)' => 'Failed to retrieve ORCID access token',
                    'Known non-critical conditional GET If-Match mismatch' => 'If-Match header should contain',
                ]
            ),
        ];
    }
}
